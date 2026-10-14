import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a program cycle is in its life cycle.
    enum ProgramCycleStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a program cycle and its current status.
    final class ProgramCycle {
        var code: String
        var title: String
        var ward: String
        var diagnosisCode: String
        var summary: String
        var payer: String
        var score: Double
        var status: ProgramCycleStatus

        init(code: String, title: String, ward: String, diagnosisCode: String, summary: String, payer: String, score: Double, status: ProgramCycleStatus) {
            self.code = code
            self.title = title
            self.ward = ward
            self.diagnosisCode = diagnosisCode
            self.summary = summary
            self.payer = payer
            self.score = score
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

        func canMoveTo(_ next: ProgramCycleStatus) -> Bool {
            switch status {
            case .created:
                return next == ProgramCycleStatus.published
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == ProgramCycleStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ProgramCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("program cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("program cycle") \(code)"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> ProgramCycle {
            return ProgramCycle(
                code: code,
                title: title,
                ward: ward,
                diagnosisCode: diagnosisCode,
                summary: summary,
                payer: payer,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a program cycle in status created.
    static func newProgramCycle(_ code: String, title: String) -> ProgramCycle {
        return ProgramCycle(
            code: code,
            title: title,
            ward: "",
            diagnosisCode: "",
            summary: "",
            payer: "",
            score: 0.0,
            status: ProgramCycleStatus.created
        )
    }
}
