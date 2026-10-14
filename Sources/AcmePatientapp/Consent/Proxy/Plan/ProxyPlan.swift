import AcmePlatform
import Foundation

extension Consent {
    /// Where a proxy plan is in its life cycle.
    enum ProxyPlanStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A proxy plan as the proxy team keeps it.
    final class ProxyPlan {
        var code: String
        var title: String
        var reviewer: String
        var margin: Double
        var visible: Bool
        var payer: String
        var encounterID: String
        var status: ProxyPlanStatus

        init(code: String, title: String, reviewer: String, margin: Double, visible: Bool, payer: String, encounterID: String, status: ProxyPlanStatus) {
            self.code = code
            self.title = title
            self.reviewer = reviewer
            self.margin = margin
            self.visible = visible
            self.payer = payer
            self.encounterID = encounterID
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

        func canMoveTo(_ next: ProxyPlanStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == ProxyPlanStatus.closed
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == ProxyPlanStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ProxyPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("proxy plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("proxy plan") \(code)"
        }

        func measuredValue() -> Double {
            return margin
        }

        func copyValue() -> ProxyPlan {
            return ProxyPlan(
                code: code,
                title: title,
                reviewer: reviewer,
                margin: margin,
                visible: visible,
                payer: payer,
                encounterID: encounterID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a proxy plan in status draft.
    static func newProxyPlan(_ code: String, title: String) -> ProxyPlan {
        return ProxyPlan(
            code: code,
            title: title,
            reviewer: "",
            margin: 0.0,
            visible: false,
            payer: "",
            encounterID: "",
            status: ProxyPlanStatus.draft
        )
    }
}
