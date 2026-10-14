import AcmePlatform
import Foundation

extension Labs {
    /// Where a scheduled accession milestone is in its life cycle.
    enum ScheduledAccessionMilestoneStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A scheduled accession milestone as the accession team keeps it.
    final class ScheduledAccessionMilestone {
        var code: String
        var label: String
        var ward: String
        var maximum: Double
        var endsAt: Int
        var phone: String
        var segment: String
        var status: ScheduledAccessionMilestoneStatus

        init(code: String, label: String, ward: String, maximum: Double, endsAt: Int, phone: String, segment: String, status: ScheduledAccessionMilestoneStatus) {
            self.code = code
            self.label = label
            self.ward = ward
            self.maximum = maximum
            self.endsAt = endsAt
            self.phone = phone
            self.segment = segment
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ScheduledAccessionMilestoneStatus) -> Bool {
            switch status {
            case .proposed:
                return next == ScheduledAccessionMilestoneStatus.withdrawn
            case .approved:
                return next == ScheduledAccessionMilestoneStatus.rejected || next == ScheduledAccessionMilestoneStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: ScheduledAccessionMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled accession milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func netVolume() -> Double {
            return ((maximum - Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledAccessionMilestone {
            return ScheduledAccessionMilestone(
                code: code,
                label: label,
                ward: ward,
                maximum: maximum,
                endsAt: endsAt,
                phone: phone,
                segment: segment,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a scheduled accession milestone in status proposed.
    static func newScheduledAccessionMilestone(_ code: String, label: String) -> ScheduledAccessionMilestone {
        return ScheduledAccessionMilestone(
            code: code,
            label: label,
            ward: "",
            maximum: 0.0,
            endsAt: 0,
            phone: "",
            segment: "",
            status: ScheduledAccessionMilestoneStatus.proposed
        )
    }
}
