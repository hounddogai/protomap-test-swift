import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a census milestone is in its life cycle.
    enum CensusMilestoneStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A census milestone as the census team keeps it.
    final class CensusMilestone {
        var code: String
        var title: String
        var amount: Double
        var currency: String
        var description: String
        var status: CensusMilestoneStatus

        init(code: String, title: String, amount: Double, currency: String, description: String, status: CensusMilestoneStatus) {
            self.code = code
            self.title = title
            self.amount = amount
            self.currency = currency
            self.description = description
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

        func canMoveTo(_ next: CensusMilestoneStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == CensusMilestoneStatus.draining || next == CensusMilestoneStatus.stopped
            case .draining:
                return next == CensusMilestoneStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CensusMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("census milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("census milestone") \(code)"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> CensusMilestone {
            return CensusMilestone(
                code: code,
                title: title,
                amount: amount,
                currency: currency,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a census milestone in status idle.
    static func newCensusMilestone(_ code: String, title: String) -> CensusMilestone {
        return CensusMilestone(
            code: code,
            title: title,
            amount: 0.0,
            currency: "",
            description: "",
            status: CensusMilestoneStatus.idle
        )
    }
}
