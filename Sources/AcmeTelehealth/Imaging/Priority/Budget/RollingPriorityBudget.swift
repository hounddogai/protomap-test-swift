import AcmePlatform
import Foundation

extension Imaging {
    /// Where a rolling priority budget is in its life cycle.
    enum RollingPriorityBudgetStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A rolling priority budget as the priority team keeps it.
    final class RollingPriorityBudget {
        var code: String
        var label: String
        var attributes: [String: String]
        var diagnosisCode: String
        var visible: Bool
        var score: Double
        var status: RollingPriorityBudgetStatus

        init(code: String, label: String, attributes: [String: String], diagnosisCode: String, visible: Bool, score: Double, status: RollingPriorityBudgetStatus) {
            self.code = code
            self.label = label
            self.attributes = attributes
            self.diagnosisCode = diagnosisCode
            self.visible = visible
            self.score = score
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

        func canMoveTo(_ next: RollingPriorityBudgetStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == RollingPriorityBudgetStatus.done || next == RollingPriorityBudgetStatus.failed
            case .running:
                return next == RollingPriorityBudgetStatus.done
            case .done:
                return next == RollingPriorityBudgetStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingPriorityBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling priority budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> RollingPriorityBudget {
            return RollingPriorityBudget(
                code: code,
                label: label,
                attributes: attributes,
                diagnosisCode: diagnosisCode,
                visible: visible,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a rolling priority budget in status new.
    static func newRollingPriorityBudget(_ code: String, label: String) -> RollingPriorityBudget {
        return RollingPriorityBudget(
            code: code,
            label: label,
            attributes: [:],
            diagnosisCode: "",
            visible: false,
            score: 0.0,
            status: RollingPriorityBudgetStatus.new
        )
    }
}
