/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Storage
import XCGLogger

private let log = Logger.syncLogger

public enum BookmarkType: String {
    case livemark
    case separator
    case folder
    case bookmark
    case query
    case microsummary     // Dead: now a bookmark.
    case item             // Oh, Sync.
}

public class LivemarkPayload: BookmarkBasePayload {
    private static let requiredLivemarkStringFields = ["feedUri", "siteUri"]

    override public func isValid() -> Bool {
        if !super.isValid() {
            return false
        }
        return self.hasRequiredStringFields(LivemarkPayload.requiredLivemarkStringFields)
    }
}

public class SeparatorPayload: BookmarkBasePayload {
    private static let requiredSeparatorIntegerFields = ["pos"]
    override public func isValid() -> Bool {
        if !super.isValid() {
            return false
        }
        // TODO
        return true
    }
}

public class FolderPayload: BookmarkBasePayload {
    private static let requiredFolderStringFields = ["title", "description"]
    private static let requiredFolderArrayFields = ["children"]
    override public func isValid() -> Bool {
        if !super.isValid() {
            return false
        }
        // TODO
        return true
    }
}

public class BookmarkPayload: BookmarkBasePayload {
    private static let requiredBookmarkStringFields = ["title", "bmkUri", "description", "tags", "keyword"]
    private static let optionalBookmarkBooleanFields = ["loadInSidebar"]

    override public func isValid() -> Bool {
        if !super.isValid() {
            return false
        }
        return self.hasRequiredStringFields(BookmarkPayload.requiredBookmarkStringFields) &&
               self.hasOptionalBooleanFields(BookmarkPayload.optionalBookmarkBooleanFields)
    }
}

public class BookmarkQueryPayload: BookmarkPayload {
    private static let requiredQueryStringFields = ["folderName", "queryId"]

    override public func isValid() -> Bool {
        if !super.isValid() {
            return false
        }
        return self.hasRequiredStringFields(BookmarkQueryPayload.requiredQueryStringFields)
    }
}

public class BookmarkBasePayload: CleartextPayloadJSON {
    private static let requiredStringFields: [String] = ["parentid", "parentName", "type"]
    private static let optionalBooleanFields: [String] = ["hasDupe"]

    func hasRequiredStringFields(fields: [String]) -> Bool {
        return fields.every({ self[$0].isString })
    }

    func hasOptionalStringFields(fields: [String]) -> Bool {
        return fields.every { field in
            let val = self[field]
            // Yup, 404 is not found, so this means "string or nothing".
            let valid = val.isString || val.isNull || val.asError?.code == 404
            if !valid {
                log.debug("Field \(field) is invalid: \(val).")
            }
            return valid
        }
    }

    func hasOptionalBooleanFields(fields: [String]) -> Bool {
        return fields.every { field in
            let val = self[field]
            // Yup, 404 is not found, so this means "boolean or nothing".
            let valid = val.isBool || val.isNull || val.asError?.code == 404
            if !valid {
                log.debug("Field \(field) is invalid: \(val).")
            }
            return valid
        }
    }

    public class func fromJSON(json: JSON) -> BookmarkBasePayload? {
        let p = BookmarkBasePayload(json)
        if p.isValid() {
            return p
        }
        return nil
    }

    override public func isValid() -> Bool {
        if !super.isValid() {
            return false
        }

        if self["deleted"].isBool && self["deleted"].asBool ?? false {
            return true
        }

        return self.hasOptionalBooleanFields(BookmarkBasePayload.optionalBooleanFields) &&
               self.hasRequiredStringFields(BookmarkBasePayload.requiredStringFields)
    }

    override public func equalPayloads(obj: CleartextPayloadJSON) -> Bool {
        if let p = obj as? BookmarkBasePayload {
            if !super.equalPayloads(p) {
                return false;
            }

            if p.deleted {
                return self.deleted == p.deleted
            }

            // If either record is deleted, these other fields might be missing.
            // But we just checked, so we're good to roll on.

// TODO!!!!
            
            return true
        }
        
        return false
    }
}
