import AcmePlatform
import Foundation

extension Staffing {
    /// Where a default acuity plan milestone is in its life cycle.
    enum DefaultAcuityPlanMilestoneStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A default acuity plan milestone. Its code is unique within a tenant.
    final class DefaultAcuityPlanMilestone {
        var code: String
        var title: String
        var clinicianID: String
        var capacity: Int
        var locale: String
        var notes: String
        var status: DefaultAcuityPlanMilestoneStatus

        init(code: String, title: String, clinicianID: String, capacity: Int, locale: String, notes: String, status: DefaultAcuityPlanMilestoneStatus) {
            self.code = code
            self.title = title
            self.clinicianID = clinicianID
            self.capacity = capacity
            self.locale = locale
            self.notes = notes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DefaultAcuityPlanMilestoneStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == DefaultAcuityPlanMilestoneStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultAcuityPlanMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default acuity plan milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func measuredValue() -> Double {
            return Double(capacity)
        }

        func copyValue() -> DefaultAcuityPlanMilestone {
            return DefaultAcuityPlanMilestone(
                code: code,
                title: title,
                clinicianID: clinicianID,
                capacity: capacity,
                locale: locale,
                notes: notes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a default acuity plan milestone in status created.
    static func newDefaultAcuityPlanMilestone(_ code: String, title: String) -> DefaultAcuityPlanMilestone {
        return DefaultAcuityPlanMilestone(
            code: code,
            title: title,
            clinicianID: "",
            capacity: 0,
            locale: "",
            notes: "",
            status: DefaultAcuityPlanMilestoneStatus.created
        )
    }
}
