import AcmePlatform
import Foundation

extension Imaging {
    /// Where a rolling care protocol rule is in its life cycle.
    enum RollingCareProtocolRuleStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A rolling care protocol rule. Its code is unique within a tenant.
    final class RollingCareProtocolRule {
        var code: String
        var title: String
        var visitMinutes: Int
        var score: Double
        var currency: String
        var name: String
        var region: String
        var priority: Int
        var ownerID: String
        var windowDays: Int
        var payer: String
        var status: RollingCareProtocolRuleStatus

        init(code: String, title: String, visitMinutes: Int, score: Double, currency: String, name: String, region: String, priority: Int, ownerID: String, windowDays: Int, payer: String, status: RollingCareProtocolRuleStatus) {
            self.code = code
            self.title = title
            self.visitMinutes = visitMinutes
            self.score = score
            self.currency = currency
            self.name = name
            self.region = region
            self.priority = priority
            self.ownerID = ownerID
            self.windowDays = windowDays
            self.payer = payer
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

        func canMoveTo(_ next: RollingCareProtocolRuleStatus) -> Bool {
            switch status {
            case .created:
                return next == RollingCareProtocolRuleStatus.validated || next == RollingCareProtocolRuleStatus.published
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: RollingCareProtocolRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling care protocol rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func adjustedTotal() -> Double {
            return ((Double(windowDays) + Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> RollingCareProtocolRule {
            return RollingCareProtocolRule(
                code: code,
                title: title,
                visitMinutes: visitMinutes,
                score: score,
                currency: currency,
                name: name,
                region: region,
                priority: priority,
                ownerID: ownerID,
                windowDays: windowDays,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a rolling care protocol rule in status created.
    static func newRollingCareProtocolRule(_ code: String, title: String) -> RollingCareProtocolRule {
        return RollingCareProtocolRule(
            code: code,
            title: title,
            visitMinutes: 0,
            score: 0.0,
            currency: "",
            name: "",
            region: "",
            priority: 0,
            ownerID: "",
            windowDays: 0,
            payer: "",
            status: RollingCareProtocolRuleStatus.created
        )
    }
}
