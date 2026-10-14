import AcmePlatform
import Foundation

extension Labs {
    /// Where a accession milestone is in its life cycle.
    enum AccessionMilestoneStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a accession milestone and its current status.
    final class AccessionMilestone {
        var code: String
        var name: String
        var weight: Double
        var pinned: Bool
        var clinicianID: String
        var timezone: String
        var status: AccessionMilestoneStatus

        init(code: String, name: String, weight: Double, pinned: Bool, clinicianID: String, timezone: String, status: AccessionMilestoneStatus) {
            self.code = code
            self.name = name
            self.weight = weight
            self.pinned = pinned
            self.clinicianID = clinicianID
            self.timezone = timezone
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

        func canMoveTo(_ next: AccessionMilestoneStatus) -> Bool {
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
                switch next {
                case .closed:
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
                return next == AccessionMilestoneStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AccessionMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("accession milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func measuredValue() -> Double {
            return weight
        }

        func copyValue() -> AccessionMilestone {
            return AccessionMilestone(
                code: code,
                name: name,
                weight: weight,
                pinned: pinned,
                clinicianID: clinicianID,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a accession milestone in status draft.
    static func newAccessionMilestone(_ code: String, name: String) -> AccessionMilestone {
        return AccessionMilestone(
            code: code,
            name: name,
            weight: 0.0,
            pinned: false,
            clinicianID: "",
            timezone: "",
            status: AccessionMilestoneStatus.draft
        )
    }
}
