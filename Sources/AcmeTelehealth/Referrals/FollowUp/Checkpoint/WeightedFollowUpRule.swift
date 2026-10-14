import AcmePlatform
import Foundation

extension Referrals {
    /// Where a weighted follow up rule is in its life cycle.
    enum WeightedFollowUpRuleStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A weighted follow up rule as the follow up team keeps it.
    final class WeightedFollowUpRule {
        var code: String
        var label: String
        var budget: Double
        var patientRef: String
        var locale: String
        var summary: String
        var channel: String
        var checksum: String
        var title: String
        var threshold: Double
        var status: WeightedFollowUpRuleStatus

        init(code: String, label: String, budget: Double, patientRef: String, locale: String, summary: String, channel: String, checksum: String, title: String, threshold: Double, status: WeightedFollowUpRuleStatus) {
            self.code = code
            self.label = label
            self.budget = budget
            self.patientRef = patientRef
            self.locale = locale
            self.summary = summary
            self.channel = channel
            self.checksum = checksum
            self.title = title
            self.threshold = threshold
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

        func canMoveTo(_ next: WeightedFollowUpRuleStatus) -> Bool {
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
                case .revoked:
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

        func moveTo(_ next: WeightedFollowUpRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted follow up rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("weighted follow up rule") \(code)"
        }

        func projectedLoad() -> Double {
            return (threshold * budget * 100).rounded() / 100
        }

        func copyValue() -> WeightedFollowUpRule {
            return WeightedFollowUpRule(
                code: code,
                label: label,
                budget: budget,
                patientRef: patientRef,
                locale: locale,
                summary: summary,
                channel: channel,
                checksum: checksum,
                title: title,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a weighted follow up rule in status requested.
    static func newWeightedFollowUpRule(_ code: String, label: String) -> WeightedFollowUpRule {
        return WeightedFollowUpRule(
            code: code,
            label: label,
            budget: 0.0,
            patientRef: "",
            locale: "",
            summary: "",
            channel: "",
            checksum: "",
            title: "",
            threshold: 0.0,
            status: WeightedFollowUpRuleStatus.requested
        )
    }
}
