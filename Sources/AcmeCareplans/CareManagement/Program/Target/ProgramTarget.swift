import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a program target is in its life cycle.
    enum ProgramTargetStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A program target. Its code is unique within a tenant.
    final class ProgramTarget {
        var code: String
        var label: String
        var dosageMg: Double
        var minimum: Double
        var windowDays: Int
        var bed: String
        var status: ProgramTargetStatus

        init(code: String, label: String, dosageMg: Double, minimum: Double, windowDays: Int, bed: String, status: ProgramTargetStatus) {
            self.code = code
            self.label = label
            self.dosageMg = dosageMg
            self.minimum = minimum
            self.windowDays = windowDays
            self.bed = bed
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

        func canMoveTo(_ next: ProgramTargetStatus) -> Bool {
            switch status {
            case .proposed:
                return next == ProgramTargetStatus.approved
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == ProgramTargetStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ProgramTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("program target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("program target") \(code)"
        }

        func weightedVolume() -> Double {
            return ((minimum + Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> ProgramTarget {
            return ProgramTarget(
                code: code,
                label: label,
                dosageMg: dosageMg,
                minimum: minimum,
                windowDays: windowDays,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a program target in status proposed.
    static func newProgramTarget(_ code: String, label: String) -> ProgramTarget {
        return ProgramTarget(
            code: code,
            label: label,
            dosageMg: 0.0,
            minimum: 0.0,
            windowDays: 0,
            bed: "",
            status: ProgramTargetStatus.proposed
        )
    }
}
