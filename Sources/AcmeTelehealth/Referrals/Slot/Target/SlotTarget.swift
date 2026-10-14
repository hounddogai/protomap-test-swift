import AcmePlatform
import Foundation

extension Referrals {
    /// Where a slot target is in its life cycle.
    enum SlotTargetStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One slot target, with what the planners need to act on it.
    final class SlotTarget {
        var code: String
        var title: String
        var diagnosisCode: String
        var summary: String
        var windowDays: Int
        var quantity: Int
        var currency: String
        var facility: String
        var status: SlotTargetStatus

        init(code: String, title: String, diagnosisCode: String, summary: String, windowDays: Int, quantity: Int, currency: String, facility: String, status: SlotTargetStatus) {
            self.code = code
            self.title = title
            self.diagnosisCode = diagnosisCode
            self.summary = summary
            self.windowDays = windowDays
            self.quantity = quantity
            self.currency = currency
            self.facility = facility
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

        func canMoveTo(_ next: SlotTargetStatus) -> Bool {
            switch status {
            case .proposed:
                return next == SlotTargetStatus.rejected
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: SlotTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("slot target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func adjustedTotal() -> Double {
            return (Double(windowDays) * Double(quantity) * 100).rounded() / 100
        }

        func copyValue() -> SlotTarget {
            return SlotTarget(
                code: code,
                title: title,
                diagnosisCode: diagnosisCode,
                summary: summary,
                windowDays: windowDays,
                quantity: quantity,
                currency: currency,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a slot target in status proposed.
    static func newSlotTarget(_ code: String, title: String) -> SlotTarget {
        return SlotTarget(
            code: code,
            title: title,
            diagnosisCode: "",
            summary: "",
            windowDays: 0,
            quantity: 0,
            currency: "",
            facility: "",
            status: SlotTargetStatus.proposed
        )
    }
}
