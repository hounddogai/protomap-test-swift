import AcmePlatform
import Foundation

extension Imaging {
    /// Where a rolling study cycle is in its life cycle.
    enum RollingStudyCycleStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A rolling study cycle as the study team keeps it.
    final class RollingStudyCycle {
        var code: String
        var title: String
        var procedureCode: String
        var maximum: Double
        var source: String
        var patientRef: String
        var status: RollingStudyCycleStatus

        init(code: String, title: String, procedureCode: String, maximum: Double, source: String, patientRef: String, status: RollingStudyCycleStatus) {
            self.code = code
            self.title = title
            self.procedureCode = procedureCode
            self.maximum = maximum
            self.source = source
            self.patientRef = patientRef
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RollingStudyCycleStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == RollingStudyCycleStatus.failed
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: RollingStudyCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling study cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("rolling study cycle") \(code)"
        }

        func measuredValue() -> Double {
            return maximum
        }

        func copyValue() -> RollingStudyCycle {
            return RollingStudyCycle(
                code: code,
                title: title,
                procedureCode: procedureCode,
                maximum: maximum,
                source: source,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a rolling study cycle in status new.
    static func newRollingStudyCycle(_ code: String, title: String) -> RollingStudyCycle {
        return RollingStudyCycle(
            code: code,
            title: title,
            procedureCode: "",
            maximum: 0.0,
            source: "",
            patientRef: "",
            status: RollingStudyCycleStatus.new
        )
    }
}
