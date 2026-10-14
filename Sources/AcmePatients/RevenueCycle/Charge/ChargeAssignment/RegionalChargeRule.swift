import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a regional charge rule is in its life cycle.
    enum RegionalChargeRuleStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One regional charge rule, with what the planners need to act on it.
    final class RegionalChargeRule {
        var code: String
        var title: String
        var score: Double
        var patientRef: String
        var category: String
        var ratio: Double
        var status: RegionalChargeRuleStatus

        init(code: String, title: String, score: Double, patientRef: String, category: String, ratio: Double, status: RegionalChargeRuleStatus) {
            self.code = code
            self.title = title
            self.score = score
            self.patientRef = patientRef
            self.category = category
            self.ratio = ratio
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

        func canMoveTo(_ next: RegionalChargeRuleStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: RegionalChargeRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional charge rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("regional charge rule") \(code)"
        }

        func projectedValue() -> Double {
            return (score * ratio * 100).rounded() / 100
        }

        func copyValue() -> RegionalChargeRule {
            return RegionalChargeRule(
                code: code,
                title: title,
                score: score,
                patientRef: patientRef,
                category: category,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a regional charge rule in status requested.
    static func newRegionalChargeRule(_ code: String, title: String) -> RegionalChargeRule {
        return RegionalChargeRule(
            code: code,
            title: title,
            score: 0.0,
            patientRef: "",
            category: "",
            ratio: 0.0,
            status: RegionalChargeRuleStatus.requested
        )
    }
}
