import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a fallback risk score rule is in its life cycle.
    enum FallbackRiskScoreRuleStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a fallback risk score rule and its current status.
    final class FallbackRiskScoreRule {
        var code: String
        var label: String
        var windowDays: Int
        var refills: Int
        var rate: Double
        var quantity: Int
        var status: FallbackRiskScoreRuleStatus

        init(code: String, label: String, windowDays: Int, refills: Int, rate: Double, quantity: Int, status: FallbackRiskScoreRuleStatus) {
            self.code = code
            self.label = label
            self.windowDays = windowDays
            self.refills = refills
            self.rate = rate
            self.quantity = quantity
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

        func canMoveTo(_ next: FallbackRiskScoreRuleStatus) -> Bool {
            switch status {
            case .draft:
                return next == FallbackRiskScoreRuleStatus.suspended || next == FallbackRiskScoreRuleStatus.closed
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
                return next == FallbackRiskScoreRuleStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackRiskScoreRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback risk score rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("fallback risk score rule") \(code)"
        }

        func adjustedExposure() -> Double {
            return (Double(windowDays) * Double(quantity) * 100).rounded() / 100
        }

        func copyValue() -> FallbackRiskScoreRule {
            return FallbackRiskScoreRule(
                code: code,
                label: label,
                windowDays: windowDays,
                refills: refills,
                rate: rate,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a fallback risk score rule in status draft.
    static func newFallbackRiskScoreRule(_ code: String, label: String) -> FallbackRiskScoreRule {
        return FallbackRiskScoreRule(
            code: code,
            label: label,
            windowDays: 0,
            refills: 0,
            rate: 0.0,
            quantity: 0,
            status: FallbackRiskScoreRuleStatus.draft
        )
    }
}
