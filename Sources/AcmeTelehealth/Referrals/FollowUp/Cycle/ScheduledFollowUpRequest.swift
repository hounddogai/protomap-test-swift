import AcmePlatform
import Foundation

extension Referrals {
    /// Where a scheduled follow up request is in its life cycle.
    enum ScheduledFollowUpRequestStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a scheduled follow up request and its current status.
    final class ScheduledFollowUpRequest {
        var code: String
        var label: String
        var amount: Double
        var copay: Double
        var tags: [String]
        var encounterID: String
        var graceDays: Int
        var status: ScheduledFollowUpRequestStatus

        init(code: String, label: String, amount: Double, copay: Double, tags: [String], encounterID: String, graceDays: Int, status: ScheduledFollowUpRequestStatus) {
            self.code = code
            self.label = label
            self.amount = amount
            self.copay = copay
            self.tags = tags
            self.encounterID = encounterID
            self.graceDays = graceDays
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

        func canMoveTo(_ next: ScheduledFollowUpRequestStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == ScheduledFollowUpRequestStatus.active
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledFollowUpRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled follow up request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveValue() -> Double {
            return (Double(graceDays) * amount * 100).rounded() / 100
        }

        func copyValue() -> ScheduledFollowUpRequest {
            return ScheduledFollowUpRequest(
                code: code,
                label: label,
                amount: amount,
                copay: copay,
                tags: tags,
                encounterID: encounterID,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a scheduled follow up request in status draft.
    static func newScheduledFollowUpRequest(_ code: String, label: String) -> ScheduledFollowUpRequest {
        return ScheduledFollowUpRequest(
            code: code,
            label: label,
            amount: 0.0,
            copay: 0.0,
            tags: [],
            encounterID: "",
            graceDays: 0,
            status: ScheduledFollowUpRequestStatus.draft
        )
    }
}
