import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a cleaning exception is in its life cycle.
    enum CleaningExceptionStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One cleaning exception, with what the planners need to act on it.
    final class CleaningException {
        var code: String
        var label: String
        var approved: Bool
        var weight: Double
        var phone: String
        var specialty: String
        var source: String
        var bed: String
        var status: CleaningExceptionStatus

        init(code: String, label: String, approved: Bool, weight: Double, phone: String, specialty: String, source: String, bed: String, status: CleaningExceptionStatus) {
            self.code = code
            self.label = label
            self.approved = approved
            self.weight = weight
            self.phone = phone
            self.specialty = specialty
            self.source = source
            self.bed = bed
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

        func canMoveTo(_ next: CleaningExceptionStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == CleaningExceptionStatus.draining
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: CleaningExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("cleaning exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("cleaning exception") \(code)"
        }

        func measuredValue() -> Double {
            return weight
        }

        func copyValue() -> CleaningException {
            return CleaningException(
                code: code,
                label: label,
                approved: approved,
                weight: weight,
                phone: phone,
                specialty: specialty,
                source: source,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a cleaning exception in status idle.
    static func newCleaningException(_ code: String, label: String) -> CleaningException {
        return CleaningException(
            code: code,
            label: label,
            approved: false,
            weight: 0.0,
            phone: "",
            specialty: "",
            source: "",
            bed: "",
            status: CleaningExceptionStatus.idle
        )
    }
}
