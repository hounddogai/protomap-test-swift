import AcmePlatform
import Foundation

extension Consent {
    /// Where a proxy milestone is in its life cycle.
    enum ProxyMilestoneStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a proxy milestone and its current status.
    final class ProxyMilestone {
        var code: String
        var name: String
        var currency: String
        var facility: String
        var retries: Int
        var payer: String
        var procedureCode: String
        var status: ProxyMilestoneStatus

        init(code: String, name: String, currency: String, facility: String, retries: Int, payer: String, procedureCode: String, status: ProxyMilestoneStatus) {
            self.code = code
            self.name = name
            self.currency = currency
            self.facility = facility
            self.retries = retries
            self.payer = payer
            self.procedureCode = procedureCode
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

        func canMoveTo(_ next: ProxyMilestoneStatus) -> Bool {
            switch status {
            case .created:
                return next == ProxyMilestoneStatus.published
            case .validated:
                return next == ProxyMilestoneStatus.retired
            case .published:
                return next == ProxyMilestoneStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ProxyMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("proxy milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func measuredValue() -> Double {
            return Double(retries)
        }

        func copyValue() -> ProxyMilestone {
            return ProxyMilestone(
                code: code,
                name: name,
                currency: currency,
                facility: facility,
                retries: retries,
                payer: payer,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a proxy milestone in status created.
    static func newProxyMilestone(_ code: String, name: String) -> ProxyMilestone {
        return ProxyMilestone(
            code: code,
            name: name,
            currency: "",
            facility: "",
            retries: 0,
            payer: "",
            procedureCode: "",
            status: ProxyMilestoneStatus.created
        )
    }
}
