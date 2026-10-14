import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a adaptive transfer schedule is in its life cycle.
    enum AdaptiveTransferScheduleStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One adaptive transfer schedule, with what the planners need to act on it.
    final class AdaptiveTransferSchedule {
        var code: String
        var title: String
        var discount: Double
        var phone: String
        var acuity: Int
        var maximum: Double
        var currency: String
        var revision: Int
        var status: AdaptiveTransferScheduleStatus

        init(code: String, title: String, discount: Double, phone: String, acuity: Int, maximum: Double, currency: String, revision: Int, status: AdaptiveTransferScheduleStatus) {
            self.code = code
            self.title = title
            self.discount = discount
            self.phone = phone
            self.acuity = acuity
            self.maximum = maximum
            self.currency = currency
            self.revision = revision
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

        func canMoveTo(_ next: AdaptiveTransferScheduleStatus) -> Bool {
            switch status {
            case .proposed:
                return next == AdaptiveTransferScheduleStatus.withdrawn
            case .approved:
                return next == AdaptiveTransferScheduleStatus.rejected || next == AdaptiveTransferScheduleStatus.withdrawn
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

        func moveTo(_ next: AdaptiveTransferScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive transfer schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func effectiveValue() -> Double {
            return (discount * maximum * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveTransferSchedule {
            return AdaptiveTransferSchedule(
                code: code,
                title: title,
                discount: discount,
                phone: phone,
                acuity: acuity,
                maximum: maximum,
                currency: currency,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a adaptive transfer schedule in status proposed.
    static func newAdaptiveTransferSchedule(_ code: String, title: String) -> AdaptiveTransferSchedule {
        return AdaptiveTransferSchedule(
            code: code,
            title: title,
            discount: 0.0,
            phone: "",
            acuity: 0,
            maximum: 0.0,
            currency: "",
            revision: 0,
            status: AdaptiveTransferScheduleStatus.proposed
        )
    }
}
