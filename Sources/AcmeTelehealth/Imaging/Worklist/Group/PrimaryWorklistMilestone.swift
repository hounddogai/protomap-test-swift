import AcmePlatform
import Foundation

extension Imaging {
    /// Where a primary worklist milestone is in its life cycle.
    enum PrimaryWorklistMilestoneStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a primary worklist milestone and its current status.
    final class PrimaryWorklistMilestone {
        var code: String
        var label: String
        var durationMinutes: Int
        var checksum: String
        var rate: Double
        var maximum: Double
        var acuity: Int
        var approved: Bool
        var discount: Double
        var status: PrimaryWorklistMilestoneStatus

        init(code: String, label: String, durationMinutes: Int, checksum: String, rate: Double, maximum: Double, acuity: Int, approved: Bool, discount: Double, status: PrimaryWorklistMilestoneStatus) {
            self.code = code
            self.label = label
            self.durationMinutes = durationMinutes
            self.checksum = checksum
            self.rate = rate
            self.maximum = maximum
            self.acuity = acuity
            self.approved = approved
            self.discount = discount
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

        func canMoveTo(_ next: PrimaryWorklistMilestoneStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == PrimaryWorklistMilestoneStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryWorklistMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary worklist milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func weightedExposure() -> Double {
            return ((maximum + discount) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryWorklistMilestone {
            return PrimaryWorklistMilestone(
                code: code,
                label: label,
                durationMinutes: durationMinutes,
                checksum: checksum,
                rate: rate,
                maximum: maximum,
                acuity: acuity,
                approved: approved,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a primary worklist milestone in status created.
    static func newPrimaryWorklistMilestone(_ code: String, label: String) -> PrimaryWorklistMilestone {
        return PrimaryWorklistMilestone(
            code: code,
            label: label,
            durationMinutes: 0,
            checksum: "",
            rate: 0.0,
            maximum: 0.0,
            acuity: 0,
            approved: false,
            discount: 0.0,
            status: PrimaryWorklistMilestoneStatus.created
        )
    }
}
