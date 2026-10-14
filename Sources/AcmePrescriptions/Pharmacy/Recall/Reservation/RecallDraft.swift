import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a recall draft is in its life cycle.
    enum RecallDraftStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One recall draft, with what the planners need to act on it.
    final class RecallDraft {
        var code: String
        var title: String
        var archived: Bool
        var tags: [String]
        var graceDays: Int
        var unit: String
        var description: String
        var name: String
        var status: RecallDraftStatus

        init(code: String, title: String, archived: Bool, tags: [String], graceDays: Int, unit: String, description: String, name: String, status: RecallDraftStatus) {
            self.code = code
            self.title = title
            self.archived = archived
            self.tags = tags
            self.graceDays = graceDays
            self.unit = unit
            self.description = description
            self.name = name
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RecallDraftStatus) -> Bool {
            switch status {
            case .requested:
                return next == RecallDraftStatus.expired
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == RecallDraftStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RecallDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("recall draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func measuredValue() -> Double {
            return Double(graceDays)
        }

        func copyValue() -> RecallDraft {
            return RecallDraft(
                code: code,
                title: title,
                archived: archived,
                tags: tags,
                graceDays: graceDays,
                unit: unit,
                description: description,
                name: name,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a recall draft in status requested.
    static func newRecallDraft(_ code: String, title: String) -> RecallDraft {
        return RecallDraft(
            code: code,
            title: title,
            archived: false,
            tags: [],
            graceDays: 0,
            unit: "",
            description: "",
            name: "",
            status: RecallDraftStatus.requested
        )
    }
}
