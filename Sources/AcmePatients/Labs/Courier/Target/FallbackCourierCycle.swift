import AcmePlatform
import Foundation

extension Labs {
    /// Where a fallback courier cycle is in its life cycle.
    enum FallbackCourierCycleStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One fallback courier cycle, with what the planners need to act on it.
    final class FallbackCourierCycle {
        var code: String
        var label: String
        var amount: Double
        var name: String
        var patientRef: String
        var procedureCode: String
        var score: Double
        var status: FallbackCourierCycleStatus

        init(code: String, label: String, amount: Double, name: String, patientRef: String, procedureCode: String, score: Double, status: FallbackCourierCycleStatus) {
            self.code = code
            self.label = label
            self.amount = amount
            self.name = name
            self.patientRef = patientRef
            self.procedureCode = procedureCode
            self.score = score
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FallbackCourierCycleStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: FallbackCourierCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback courier cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func weightedVolume() -> Double {
            return (score * amount * 100).rounded() / 100
        }

        func copyValue() -> FallbackCourierCycle {
            return FallbackCourierCycle(
                code: code,
                label: label,
                amount: amount,
                name: name,
                patientRef: patientRef,
                procedureCode: procedureCode,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a fallback courier cycle in status draft.
    static func newFallbackCourierCycle(_ code: String, label: String) -> FallbackCourierCycle {
        return FallbackCourierCycle(
            code: code,
            label: label,
            amount: 0.0,
            name: "",
            patientRef: "",
            procedureCode: "",
            score: 0.0,
            status: FallbackCourierCycleStatus.draft
        )
    }
}
