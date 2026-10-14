import AcmePlatform
import Foundation

extension Referrals {
    /// Where a scheduled network rule is in its life cycle.
    enum ScheduledNetworkRuleStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One scheduled network rule, with what the planners need to act on it.
    final class ScheduledNetworkRule {
        var code: String
        var title: String
        var endsAt: Int
        var cost: Double
        var encounterID: String
        var ward: String
        var label: String
        var channel: String
        var region: String
        var refills: Int
        var status: ScheduledNetworkRuleStatus

        init(code: String, title: String, endsAt: Int, cost: Double, encounterID: String, ward: String, label: String, channel: String, region: String, refills: Int, status: ScheduledNetworkRuleStatus) {
            self.code = code
            self.title = title
            self.endsAt = endsAt
            self.cost = cost
            self.encounterID = encounterID
            self.ward = ward
            self.label = label
            self.channel = channel
            self.region = region
            self.refills = refills
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ScheduledNetworkRuleStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == ScheduledNetworkRuleStatus.completed
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: ScheduledNetworkRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled network rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(title)"
        }

        func netValue() -> Double {
            return ((cost - Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledNetworkRule {
            return ScheduledNetworkRule(
                code: code,
                title: title,
                endsAt: endsAt,
                cost: cost,
                encounterID: encounterID,
                ward: ward,
                label: label,
                channel: channel,
                region: region,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a scheduled network rule in status planned.
    static func newScheduledNetworkRule(_ code: String, title: String) -> ScheduledNetworkRule {
        return ScheduledNetworkRule(
            code: code,
            title: title,
            endsAt: 0,
            cost: 0.0,
            encounterID: "",
            ward: "",
            label: "",
            channel: "",
            region: "",
            refills: 0,
            status: ScheduledNetworkRuleStatus.planned
        )
    }
}
