import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a isolation cycle is in its life cycle.
    enum IsolationCycleStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One isolation cycle, with what the planners need to act on it.
    final class IsolationCycle {
        var code: String
        var label: String
        var specialty: String
        var dosageMg: Double
        var sequence: Int
        var maximum: Double
        var score: Double
        var batchSize: Int
        var procedureCode: String
        var margin: Double
        var status: IsolationCycleStatus

        init(code: String, label: String, specialty: String, dosageMg: Double, sequence: Int, maximum: Double, score: Double, batchSize: Int, procedureCode: String, margin: Double, status: IsolationCycleStatus) {
            self.code = code
            self.label = label
            self.specialty = specialty
            self.dosageMg = dosageMg
            self.sequence = sequence
            self.maximum = maximum
            self.score = score
            self.batchSize = batchSize
            self.procedureCode = procedureCode
            self.margin = margin
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

        func canMoveTo(_ next: IsolationCycleStatus) -> Bool {
            switch status {
            case .requested:
                return next == IsolationCycleStatus.expired
            case .granted:
                return next == IsolationCycleStatus.revoked
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

        func moveTo(_ next: IsolationCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("isolation cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("isolation cycle") \(code)"
        }

        func adjustedTotal() -> Double {
            return (margin * dosageMg * 100).rounded() / 100
        }

        func copyValue() -> IsolationCycle {
            return IsolationCycle(
                code: code,
                label: label,
                specialty: specialty,
                dosageMg: dosageMg,
                sequence: sequence,
                maximum: maximum,
                score: score,
                batchSize: batchSize,
                procedureCode: procedureCode,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a isolation cycle in status requested.
    static func newIsolationCycle(_ code: String, label: String) -> IsolationCycle {
        return IsolationCycle(
            code: code,
            label: label,
            specialty: "",
            dosageMg: 0.0,
            sequence: 0,
            maximum: 0.0,
            score: 0.0,
            batchSize: 0,
            procedureCode: "",
            margin: 0.0,
            status: IsolationCycleStatus.requested
        )
    }
}
