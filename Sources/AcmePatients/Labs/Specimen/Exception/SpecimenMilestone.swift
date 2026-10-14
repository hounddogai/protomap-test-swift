import AcmePlatform
import Foundation

extension Labs {
    /// Where a specimen milestone is in its life cycle.
    enum SpecimenMilestoneStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A specimen milestone. Its code is unique within a tenant.
    final class SpecimenMilestone {
        var code: String
        var label: String
        var facility: String
        var retries: Int
        var timezone: String
        var description: String
        var status: SpecimenMilestoneStatus

        init(code: String, label: String, facility: String, retries: Int, timezone: String, description: String, status: SpecimenMilestoneStatus) {
            self.code = code
            self.label = label
            self.facility = facility
            self.retries = retries
            self.timezone = timezone
            self.description = description
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SpecimenMilestoneStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == SpecimenMilestoneStatus.ready
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == SpecimenMilestoneStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SpecimenMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("specimen milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("specimen milestone") \(code)"
        }

        func measuredValue() -> Double {
            return Double(retries)
        }

        func copyValue() -> SpecimenMilestone {
            return SpecimenMilestone(
                code: code,
                label: label,
                facility: facility,
                retries: retries,
                timezone: timezone,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a specimen milestone in status idle.
    static func newSpecimenMilestone(_ code: String, label: String) -> SpecimenMilestone {
        return SpecimenMilestone(
            code: code,
            label: label,
            facility: "",
            retries: 0,
            timezone: "",
            description: "",
            status: SpecimenMilestoneStatus.idle
        )
    }
}
