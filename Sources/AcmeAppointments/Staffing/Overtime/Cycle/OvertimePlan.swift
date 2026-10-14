import AcmePlatform
import Foundation

extension Staffing {
    /// Where a overtime plan is in its life cycle.
    enum OvertimePlanStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a overtime plan and its current status.
    final class OvertimePlan {
        var code: String
        var title: String
        var threshold: Double
        var capacity: Int
        var phone: String
        var status: OvertimePlanStatus

        init(code: String, title: String, threshold: Double, capacity: Int, phone: String, status: OvertimePlanStatus) {
            self.code = code
            self.title = title
            self.threshold = threshold
            self.capacity = capacity
            self.phone = phone
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: OvertimePlanStatus) -> Bool {
            switch status {
            case .proposed:
                return next == OvertimePlanStatus.rejected || next == OvertimePlanStatus.withdrawn
            case .approved:
                return next == OvertimePlanStatus.rejected || next == OvertimePlanStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: OvertimePlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("overtime plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func adjustedValue() -> Double {
            return ((threshold + Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> OvertimePlan {
            return OvertimePlan(
                code: code,
                title: title,
                threshold: threshold,
                capacity: capacity,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a overtime plan in status proposed.
    static func newOvertimePlan(_ code: String, title: String) -> OvertimePlan {
        return OvertimePlan(
            code: code,
            title: title,
            threshold: 0.0,
            capacity: 0,
            phone: "",
            status: OvertimePlanStatus.proposed
        )
    }
}
