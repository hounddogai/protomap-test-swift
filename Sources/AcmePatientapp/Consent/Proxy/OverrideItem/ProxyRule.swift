import AcmePlatform
import Foundation

extension Consent {
    /// Where a proxy rule is in its life cycle.
    enum ProxyRuleStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a proxy rule and its current status.
    final class ProxyRule {
        var code: String
        var title: String
        var cost: Double
        var weight: Double
        var diagnosisCode: String
        var threshold: Double
        var facility: String
        var channel: String
        var durationMinutes: Int
        var status: ProxyRuleStatus

        init(code: String, title: String, cost: Double, weight: Double, diagnosisCode: String, threshold: Double, facility: String, channel: String, durationMinutes: Int, status: ProxyRuleStatus) {
            self.code = code
            self.title = title
            self.cost = cost
            self.weight = weight
            self.diagnosisCode = diagnosisCode
            self.threshold = threshold
            self.facility = facility
            self.channel = channel
            self.durationMinutes = durationMinutes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ProxyRuleStatus) -> Bool {
            switch status {
            case .`open`:
                return next == ProxyRuleStatus.resolved
            case .inReview:
                return next == ProxyRuleStatus.resolved
            case .resolved:
                return next == ProxyRuleStatus.reopened || next == ProxyRuleStatus.archived
            case .reopened:
                return next == ProxyRuleStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ProxyRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("proxy rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func adjustedLoad() -> Double {
            return ((weight - cost) * 100).rounded() / 100
        }

        func copyValue() -> ProxyRule {
            return ProxyRule(
                code: code,
                title: title,
                cost: cost,
                weight: weight,
                diagnosisCode: diagnosisCode,
                threshold: threshold,
                facility: facility,
                channel: channel,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a proxy rule in status open.
    static func newProxyRule(_ code: String, title: String) -> ProxyRule {
        return ProxyRule(
            code: code,
            title: title,
            cost: 0.0,
            weight: 0.0,
            diagnosisCode: "",
            threshold: 0.0,
            facility: "",
            channel: "",
            durationMinutes: 0,
            status: ProxyRuleStatus.`open`
        )
    }
}
