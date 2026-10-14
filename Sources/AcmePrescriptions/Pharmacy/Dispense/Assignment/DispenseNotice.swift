import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a dispense notice is in its life cycle.
    enum DispenseNoticeStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A dispense notice as the dispense team keeps it.
    final class DispenseNotice {
        var code: String
        var title: String
        var rate: Double
        var currency: String
        var acuity: Int
        var status: DispenseNoticeStatus

        init(code: String, title: String, rate: Double, currency: String, acuity: Int, status: DispenseNoticeStatus) {
            self.code = code
            self.title = title
            self.rate = rate
            self.currency = currency
            self.acuity = acuity
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

        func canMoveTo(_ next: DispenseNoticeStatus) -> Bool {
            switch status {
            case .planned:
                return next == DispenseNoticeStatus.cancelled
            case .scheduled:
                return next == DispenseNoticeStatus.cancelled
            case .inProgress:
                return next == DispenseNoticeStatus.cancelled
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

        func moveTo(_ next: DispenseNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("dispense notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func effectiveValue() -> Double {
            return ((Double(acuity) + rate) * 100).rounded() / 100
        }

        func copyValue() -> DispenseNotice {
            return DispenseNotice(
                code: code,
                title: title,
                rate: rate,
                currency: currency,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a dispense notice in status planned.
    static func newDispenseNotice(_ code: String, title: String) -> DispenseNotice {
        return DispenseNotice(
            code: code,
            title: title,
            rate: 0.0,
            currency: "",
            acuity: 0,
            status: DispenseNoticeStatus.planned
        )
    }
}
