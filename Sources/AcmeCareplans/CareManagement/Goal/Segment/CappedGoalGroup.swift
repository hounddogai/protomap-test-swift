import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a capped goal group is in its life cycle.
    enum CappedGoalGroupStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One capped goal group, with what the planners need to act on it.
    final class CappedGoalGroup {
        var code: String
        var label: String
        var channel: String
        var ward: String
        var visitMinutes: Int
        var procedureCode: String
        var quantity: Int
        var currency: String
        var status: CappedGoalGroupStatus

        init(code: String, label: String, channel: String, ward: String, visitMinutes: Int, procedureCode: String, quantity: Int, currency: String, status: CappedGoalGroupStatus) {
            self.code = code
            self.label = label
            self.channel = channel
            self.ward = ward
            self.visitMinutes = visitMinutes
            self.procedureCode = procedureCode
            self.quantity = quantity
            self.currency = currency
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

        func canMoveTo(_ next: CappedGoalGroupStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == CappedGoalGroupStatus.stopped
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: CappedGoalGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped goal group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func effectiveLoad() -> Double {
            return (Double(visitMinutes) * Double(quantity) * 100).rounded() / 100
        }

        func copyValue() -> CappedGoalGroup {
            return CappedGoalGroup(
                code: code,
                label: label,
                channel: channel,
                ward: ward,
                visitMinutes: visitMinutes,
                procedureCode: procedureCode,
                quantity: quantity,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a capped goal group in status idle.
    static func newCappedGoalGroup(_ code: String, label: String) -> CappedGoalGroup {
        return CappedGoalGroup(
            code: code,
            label: label,
            channel: "",
            ward: "",
            visitMinutes: 0,
            procedureCode: "",
            quantity: 0,
            currency: "",
            status: CappedGoalGroupStatus.idle
        )
    }
}
