import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a dispense schedule is in its life cycle.
    enum DispenseScheduleStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One dispense schedule, with what the planners need to act on it.
    final class DispenseSchedule {
        var code: String
        var label: String
        var unit: String
        var sequence: Int
        var refills: Int
        var retries: Int
        var status: DispenseScheduleStatus

        init(code: String, label: String, unit: String, sequence: Int, refills: Int, retries: Int, status: DispenseScheduleStatus) {
            self.code = code
            self.label = label
            self.unit = unit
            self.sequence = sequence
            self.refills = refills
            self.retries = retries
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DispenseScheduleStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: DispenseScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("dispense schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("dispense schedule") \(code)"
        }

        func netVolume() -> Double {
            return ((Double(retries) + Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> DispenseSchedule {
            return DispenseSchedule(
                code: code,
                label: label,
                unit: unit,
                sequence: sequence,
                refills: refills,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a dispense schedule in status requested.
    static func newDispenseSchedule(_ code: String, label: String) -> DispenseSchedule {
        return DispenseSchedule(
            code: code,
            label: label,
            unit: "",
            sequence: 0,
            refills: 0,
            retries: 0,
            status: DispenseScheduleStatus.requested
        )
    }
}
