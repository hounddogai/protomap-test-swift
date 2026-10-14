import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a handoff budget is in its life cycle.
    enum HandoffBudgetStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a handoff budget and its current status.
    final class HandoffBudget {
        var code: String
        var name: String
        var minimum: Double
        var diagnosisCode: String
        var ward: String
        var maximum: Double
        var region: String
        var status: HandoffBudgetStatus

        init(code: String, name: String, minimum: Double, diagnosisCode: String, ward: String, maximum: Double, region: String, status: HandoffBudgetStatus) {
            self.code = code
            self.name = name
            self.minimum = minimum
            self.diagnosisCode = diagnosisCode
            self.ward = ward
            self.maximum = maximum
            self.region = region
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

        func canMoveTo(_ next: HandoffBudgetStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == HandoffBudgetStatus.active
            case .active:
                return next == HandoffBudgetStatus.suspended || next == HandoffBudgetStatus.closed
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

        func moveTo(_ next: HandoffBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("handoff budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func adjustedLoad() -> Double {
            return ((minimum - maximum) * 100).rounded() / 100
        }

        func copyValue() -> HandoffBudget {
            return HandoffBudget(
                code: code,
                name: name,
                minimum: minimum,
                diagnosisCode: diagnosisCode,
                ward: ward,
                maximum: maximum,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a handoff budget in status draft.
    static func newHandoffBudget(_ code: String, name: String) -> HandoffBudget {
        return HandoffBudget(
            code: code,
            name: name,
            minimum: 0.0,
            diagnosisCode: "",
            ward: "",
            maximum: 0.0,
            region: "",
            status: HandoffBudgetStatus.draft
        )
    }
}
