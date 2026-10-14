import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a outreach draft is in its life cycle.
    enum OutreachDraftStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A outreach draft as the outreach team keeps it.
    final class OutreachDraft {
        var code: String
        var title: String
        var amount: Double
        var attributes: [String: String]
        var pinned: Bool
        var status: OutreachDraftStatus

        init(code: String, title: String, amount: Double, attributes: [String: String], pinned: Bool, status: OutreachDraftStatus) {
            self.code = code
            self.title = title
            self.amount = amount
            self.attributes = attributes
            self.pinned = pinned
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: OutreachDraftStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == OutreachDraftStatus.reopened
            case .resolved:
                return next == OutreachDraftStatus.archived
            case .reopened:
                return next == OutreachDraftStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: OutreachDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("outreach draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> OutreachDraft {
            return OutreachDraft(
                code: code,
                title: title,
                amount: amount,
                attributes: attributes,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a outreach draft in status open.
    static func newOutreachDraft(_ code: String, title: String) -> OutreachDraft {
        return OutreachDraft(
            code: code,
            title: title,
            amount: 0.0,
            attributes: [:],
            pinned: false,
            status: OutreachDraftStatus.`open`
        )
    }
}
