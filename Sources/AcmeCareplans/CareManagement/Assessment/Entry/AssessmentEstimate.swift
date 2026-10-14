import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a assessment estimate is in its life cycle.
    enum AssessmentEstimateStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a assessment estimate and its current status.
    final class AssessmentEstimate {
        var code: String
        var name: String
        var procedureCode: String
        var cost: Double
        var channel: String
        var notes: String
        var status: AssessmentEstimateStatus

        init(code: String, name: String, procedureCode: String, cost: Double, channel: String, notes: String, status: AssessmentEstimateStatus) {
            self.code = code
            self.name = name
            self.procedureCode = procedureCode
            self.cost = cost
            self.channel = channel
            self.notes = notes
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

        func canMoveTo(_ next: AssessmentEstimateStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == AssessmentEstimateStatus.active || next == AssessmentEstimateStatus.closed
            case .active:
                switch next {
                case .suspended, .closed:
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

        func moveTo(_ next: AssessmentEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("assessment estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("assessment estimate") \(code)"
        }

        func measuredValue() -> Double {
            return cost
        }

        func copyValue() -> AssessmentEstimate {
            return AssessmentEstimate(
                code: code,
                name: name,
                procedureCode: procedureCode,
                cost: cost,
                channel: channel,
                notes: notes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a assessment estimate in status draft.
    static func newAssessmentEstimate(_ code: String, name: String) -> AssessmentEstimate {
        return AssessmentEstimate(
            code: code,
            name: name,
            procedureCode: "",
            cost: 0.0,
            channel: "",
            notes: "",
            status: AssessmentEstimateStatus.draft
        )
    }
}
