import AcmePlatform
import Foundation

extension Labs {
    /// Where a courier entry is in its life cycle.
    enum CourierEntryStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One courier entry, with what the planners need to act on it.
    final class CourierEntry {
        var code: String
        var title: String
        var score: Double
        var contactEmail: String
        var updatedAt: Int
        var ratio: Double
        var tags: [String]
        var status: CourierEntryStatus

        init(code: String, title: String, score: Double, contactEmail: String, updatedAt: Int, ratio: Double, tags: [String], status: CourierEntryStatus) {
            self.code = code
            self.title = title
            self.score = score
            self.contactEmail = contactEmail
            self.updatedAt = updatedAt
            self.ratio = ratio
            self.tags = tags
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CourierEntryStatus) -> Bool {
            switch status {
            case .draft:
                return next == CourierEntryStatus.pending || next == CourierEntryStatus.suspended
            case .pending:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == CourierEntryStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CourierEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("courier entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveExposure() -> Double {
            return (score * Double(updatedAt) * 100).rounded() / 100
        }

        func copyValue() -> CourierEntry {
            return CourierEntry(
                code: code,
                title: title,
                score: score,
                contactEmail: contactEmail,
                updatedAt: updatedAt,
                ratio: ratio,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a courier entry in status draft.
    static func newCourierEntry(_ code: String, title: String) -> CourierEntry {
        return CourierEntry(
            code: code,
            title: title,
            score: 0.0,
            contactEmail: "",
            updatedAt: 0,
            ratio: 0.0,
            tags: [],
            status: CourierEntryStatus.draft
        )
    }
}
