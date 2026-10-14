import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a global interaction baseline is in its life cycle.
    enum GlobalInteractionBaselineStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One global interaction baseline, with what the planners need to act on it.
    final class GlobalInteractionBaseline {
        var code: String
        var label: String
        var timezone: String
        var procedureCode: String
        var budget: Double
        var visitMinutes: Int
        var status: GlobalInteractionBaselineStatus

        init(code: String, label: String, timezone: String, procedureCode: String, budget: Double, visitMinutes: Int, status: GlobalInteractionBaselineStatus) {
            self.code = code
            self.label = label
            self.timezone = timezone
            self.procedureCode = procedureCode
            self.budget = budget
            self.visitMinutes = visitMinutes
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

        func canMoveTo(_ next: GlobalInteractionBaselineStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == GlobalInteractionBaselineStatus.retired
            case .published:
                return next == GlobalInteractionBaselineStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalInteractionBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global interaction baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("global interaction baseline") \(code)"
        }

        func adjustedValue() -> Double {
            return (Double(visitMinutes) * budget * 100).rounded() / 100
        }

        func copyValue() -> GlobalInteractionBaseline {
            return GlobalInteractionBaseline(
                code: code,
                label: label,
                timezone: timezone,
                procedureCode: procedureCode,
                budget: budget,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a global interaction baseline in status created.
    static func newGlobalInteractionBaseline(_ code: String, label: String) -> GlobalInteractionBaseline {
        return GlobalInteractionBaseline(
            code: code,
            label: label,
            timezone: "",
            procedureCode: "",
            budget: 0.0,
            visitMinutes: 0,
            status: GlobalInteractionBaselineStatus.created
        )
    }
}
