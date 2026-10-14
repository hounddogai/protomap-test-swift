import AcmePlatform
import Foundation

extension Staffing {
    /// Where a fallback skill mix template is in its life cycle.
    enum FallbackSkillMixTemplateStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A fallback skill mix template. Its code is unique within a tenant.
    final class FallbackSkillMixTemplate {
        var code: String
        var label: String
        var score: Double
        var discount: Double
        var version: Int
        var timezone: String
        var refills: Int
        var amount: Double
        var region: String
        var graceDays: Int
        var budget: Double
        var status: FallbackSkillMixTemplateStatus

        init(code: String, label: String, score: Double, discount: Double, version: Int, timezone: String, refills: Int, amount: Double, region: String, graceDays: Int, budget: Double, status: FallbackSkillMixTemplateStatus) {
            self.code = code
            self.label = label
            self.score = score
            self.discount = discount
            self.version = version
            self.timezone = timezone
            self.refills = refills
            self.amount = amount
            self.region = region
            self.graceDays = graceDays
            self.budget = budget
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FallbackSkillMixTemplateStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .ready:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == FallbackSkillMixTemplateStatus.ready || next == FallbackSkillMixTemplateStatus.stopped
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == FallbackSkillMixTemplateStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackSkillMixTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback skill mix template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func weightedValue() -> Double {
            return (Double(graceDays) * budget * 100).rounded() / 100
        }

        func copyValue() -> FallbackSkillMixTemplate {
            return FallbackSkillMixTemplate(
                code: code,
                label: label,
                score: score,
                discount: discount,
                version: version,
                timezone: timezone,
                refills: refills,
                amount: amount,
                region: region,
                graceDays: graceDays,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a fallback skill mix template in status idle.
    static func newFallbackSkillMixTemplate(_ code: String, label: String) -> FallbackSkillMixTemplate {
        return FallbackSkillMixTemplate(
            code: code,
            label: label,
            score: 0.0,
            discount: 0.0,
            version: 0,
            timezone: "",
            refills: 0,
            amount: 0.0,
            region: "",
            graceDays: 0,
            budget: 0.0,
            status: FallbackSkillMixTemplateStatus.idle
        )
    }
}
