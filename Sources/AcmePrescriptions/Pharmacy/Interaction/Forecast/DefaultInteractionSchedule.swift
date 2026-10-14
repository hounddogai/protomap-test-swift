import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a default interaction schedule is in its life cycle.
    enum DefaultInteractionScheduleStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One default interaction schedule, with what the planners need to act on it.
    final class DefaultInteractionSchedule {
        var code: String
        var label: String
        var payer: String
        var version: Int
        var allergy: String
        var capacity: Int
        var status: DefaultInteractionScheduleStatus

        init(code: String, label: String, payer: String, version: Int, allergy: String, capacity: Int, status: DefaultInteractionScheduleStatus) {
            self.code = code
            self.label = label
            self.payer = payer
            self.version = version
            self.allergy = allergy
            self.capacity = capacity
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

        func canMoveTo(_ next: DefaultInteractionScheduleStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == DefaultInteractionScheduleStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultInteractionScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default interaction schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func effectiveTotal() -> Double {
            return ((Double(capacity) + Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> DefaultInteractionSchedule {
            return DefaultInteractionSchedule(
                code: code,
                label: label,
                payer: payer,
                version: version,
                allergy: allergy,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a default interaction schedule in status proposed.
    static func newDefaultInteractionSchedule(_ code: String, label: String) -> DefaultInteractionSchedule {
        return DefaultInteractionSchedule(
            code: code,
            label: label,
            payer: "",
            version: 0,
            allergy: "",
            capacity: 0,
            status: DefaultInteractionScheduleStatus.proposed
        )
    }
}
