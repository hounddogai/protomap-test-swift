import AcmePlatform
import Foundation

extension Referrals {
    /// Where a referral variance is in its life cycle.
    enum ReferralVarianceStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One referral variance, with what the planners need to act on it.
    final class ReferralVariance {
        var code: String
        var title: String
        var quantity: Int
        var copay: Double
        var ratio: Double
        var channel: String
        var createdAt: Int
        var procedureCode: String
        var status: ReferralVarianceStatus

        init(code: String, title: String, quantity: Int, copay: Double, ratio: Double, channel: String, createdAt: Int, procedureCode: String, status: ReferralVarianceStatus) {
            self.code = code
            self.title = title
            self.quantity = quantity
            self.copay = copay
            self.ratio = ratio
            self.channel = channel
            self.createdAt = createdAt
            self.procedureCode = procedureCode
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

        func canMoveTo(_ next: ReferralVarianceStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed, .cancelled:
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
                return next == ReferralVarianceStatus.completed
            case .completed:
                return next == ReferralVarianceStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReferralVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("referral variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("referral variance") \(code)"
        }

        func weightedLoad() -> Double {
            return ((Double(createdAt) + Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> ReferralVariance {
            return ReferralVariance(
                code: code,
                title: title,
                quantity: quantity,
                copay: copay,
                ratio: ratio,
                channel: channel,
                createdAt: createdAt,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a referral variance in status planned.
    static func newReferralVariance(_ code: String, title: String) -> ReferralVariance {
        return ReferralVariance(
            code: code,
            title: title,
            quantity: 0,
            copay: 0.0,
            ratio: 0.0,
            channel: "",
            createdAt: 0,
            procedureCode: "",
            status: ReferralVarianceStatus.planned
        )
    }
}
