import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a remittance rule is in its life cycle.
    enum RemittanceRuleStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a remittance rule and its current status.
    final class RemittanceRule {
        var code: String
        var title: String
        var bed: String
        var floorValue: Double
        var budget: Double
        var status: RemittanceRuleStatus

        init(code: String, title: String, bed: String, floorValue: Double, budget: Double, status: RemittanceRuleStatus) {
            self.code = code
            self.title = title
            self.bed = bed
            self.floorValue = floorValue
            self.budget = budget
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

        func canMoveTo(_ next: RemittanceRuleStatus) -> Bool {
            switch status {
            case .new:
                return next == RemittanceRuleStatus.done
            case .queued:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: RemittanceRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("remittance rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func effectiveTotal() -> Double {
            return ((floorValue - budget) * 100).rounded() / 100
        }

        func copyValue() -> RemittanceRule {
            return RemittanceRule(
                code: code,
                title: title,
                bed: bed,
                floorValue: floorValue,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a remittance rule in status new.
    static func newRemittanceRule(_ code: String, title: String) -> RemittanceRule {
        return RemittanceRule(
            code: code,
            title: title,
            bed: "",
            floorValue: 0.0,
            budget: 0.0,
            status: RemittanceRuleStatus.new
        )
    }
}
