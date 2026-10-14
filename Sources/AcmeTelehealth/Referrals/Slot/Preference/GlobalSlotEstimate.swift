import AcmePlatform
import Foundation

extension Referrals {
    /// Where a global slot estimate is in its life cycle.
    enum GlobalSlotEstimateStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A global slot estimate as the slot team keeps it.
    final class GlobalSlotEstimate {
        var code: String
        var title: String
        var acuity: Int
        var margin: Double
        var expiresAt: Int
        var channel: String
        var allergy: String
        var currency: String
        var status: GlobalSlotEstimateStatus

        init(code: String, title: String, acuity: Int, margin: Double, expiresAt: Int, channel: String, allergy: String, currency: String, status: GlobalSlotEstimateStatus) {
            self.code = code
            self.title = title
            self.acuity = acuity
            self.margin = margin
            self.expiresAt = expiresAt
            self.channel = channel
            self.allergy = allergy
            self.currency = currency
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

        func canMoveTo(_ next: GlobalSlotEstimateStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == GlobalSlotEstimateStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalSlotEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global slot estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func netVolume() -> Double {
            return ((Double(expiresAt) + margin) * 100).rounded() / 100
        }

        func copyValue() -> GlobalSlotEstimate {
            return GlobalSlotEstimate(
                code: code,
                title: title,
                acuity: acuity,
                margin: margin,
                expiresAt: expiresAt,
                channel: channel,
                allergy: allergy,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a global slot estimate in status planned.
    static func newGlobalSlotEstimate(_ code: String, title: String) -> GlobalSlotEstimate {
        return GlobalSlotEstimate(
            code: code,
            title: title,
            acuity: 0,
            margin: 0.0,
            expiresAt: 0,
            channel: "",
            allergy: "",
            currency: "",
            status: GlobalSlotEstimateStatus.planned
        )
    }
}
