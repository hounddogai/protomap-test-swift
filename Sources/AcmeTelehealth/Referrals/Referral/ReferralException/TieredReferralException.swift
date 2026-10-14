import AcmePlatform
import Foundation

extension Referrals {
    /// Where a tiered referral exception is in its life cycle.
    enum TieredReferralExceptionStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A tiered referral exception. Its code is unique within a tenant.
    final class TieredReferralException {
        var code: String
        var title: String
        var visitMinutes: Int
        var startsAt: Int
        var cost: Double
        var specialty: String
        var payer: String
        var attributes: [String: String]
        var maximum: Double
        var status: TieredReferralExceptionStatus

        init(code: String, title: String, visitMinutes: Int, startsAt: Int, cost: Double, specialty: String, payer: String, attributes: [String: String], maximum: Double, status: TieredReferralExceptionStatus) {
            self.code = code
            self.title = title
            self.visitMinutes = visitMinutes
            self.startsAt = startsAt
            self.cost = cost
            self.specialty = specialty
            self.payer = payer
            self.attributes = attributes
            self.maximum = maximum
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

        func canMoveTo(_ next: TieredReferralExceptionStatus) -> Bool {
            switch status {
            case .planned:
                return next == TieredReferralExceptionStatus.completed || next == TieredReferralExceptionStatus.cancelled
            case .scheduled:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == TieredReferralExceptionStatus.completed
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

        func moveTo(_ next: TieredReferralExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered referral exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("tiered referral exception") \(code)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func adjustedLoad() -> Double {
            return ((cost - Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> TieredReferralException {
            return TieredReferralException(
                code: code,
                title: title,
                visitMinutes: visitMinutes,
                startsAt: startsAt,
                cost: cost,
                specialty: specialty,
                payer: payer,
                attributes: attributes,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a tiered referral exception in status planned.
    static func newTieredReferralException(_ code: String, title: String) -> TieredReferralException {
        return TieredReferralException(
            code: code,
            title: title,
            visitMinutes: 0,
            startsAt: 0,
            cost: 0.0,
            specialty: "",
            payer: "",
            attributes: [:],
            maximum: 0.0,
            status: TieredReferralExceptionStatus.planned
        )
    }
}
