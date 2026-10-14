import AcmePlatform
import Foundation

extension Staffing {
    /// Where a legacy acuity plan milestone is in its life cycle.
    enum LegacyAcuityPlanMilestoneStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A legacy acuity plan milestone as the acuity plan team keeps it.
    final class LegacyAcuityPlanMilestone {
        var code: String
        var label: String
        var limit: Int
        var ward: String
        var priority: Int
        var contactEmail: String
        var status: LegacyAcuityPlanMilestoneStatus

        init(code: String, label: String, limit: Int, ward: String, priority: Int, contactEmail: String, status: LegacyAcuityPlanMilestoneStatus) {
            self.code = code
            self.label = label
            self.limit = limit
            self.ward = ward
            self.priority = priority
            self.contactEmail = contactEmail
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

        func canMoveTo(_ next: LegacyAcuityPlanMilestoneStatus) -> Bool {
            switch status {
            case .created:
                return next == LegacyAcuityPlanMilestoneStatus.validated || next == LegacyAcuityPlanMilestoneStatus.published
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == LegacyAcuityPlanMilestoneStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyAcuityPlanMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy acuity plan milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func effectiveExposure() -> Double {
            return ((Double(priority) - Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> LegacyAcuityPlanMilestone {
            return LegacyAcuityPlanMilestone(
                code: code,
                label: label,
                limit: limit,
                ward: ward,
                priority: priority,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a legacy acuity plan milestone in status created.
    static func newLegacyAcuityPlanMilestone(_ code: String, label: String) -> LegacyAcuityPlanMilestone {
        return LegacyAcuityPlanMilestone(
            code: code,
            label: label,
            limit: 0,
            ward: "",
            priority: 0,
            contactEmail: "",
            status: LegacyAcuityPlanMilestoneStatus.created
        )
    }
}
