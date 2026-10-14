import AcmePlatform
import Foundation

extension Referrals {
    /// Where a adaptive referral exception is in its life cycle.
    enum AdaptiveReferralExceptionStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A adaptive referral exception as the referral team keeps it.
    final class AdaptiveReferralException {
        var code: String
        var title: String
        var approved: Bool
        var expiresAt: Int
        var rate: Double
        var ward: String
        var margin: Double
        var allergy: String
        var locale: String
        var facility: String
        var status: AdaptiveReferralExceptionStatus

        init(code: String, title: String, approved: Bool, expiresAt: Int, rate: Double, ward: String, margin: Double, allergy: String, locale: String, facility: String, status: AdaptiveReferralExceptionStatus) {
            self.code = code
            self.title = title
            self.approved = approved
            self.expiresAt = expiresAt
            self.rate = rate
            self.ward = ward
            self.margin = margin
            self.allergy = allergy
            self.locale = locale
            self.facility = facility
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AdaptiveReferralExceptionStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: AdaptiveReferralExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive referral exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("adaptive referral exception") \(code)"
        }

        func adjustedLoad() -> Double {
            return ((Double(expiresAt) + rate) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveReferralException {
            return AdaptiveReferralException(
                code: code,
                title: title,
                approved: approved,
                expiresAt: expiresAt,
                rate: rate,
                ward: ward,
                margin: margin,
                allergy: allergy,
                locale: locale,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a adaptive referral exception in status new.
    static func newAdaptiveReferralException(_ code: String, title: String) -> AdaptiveReferralException {
        return AdaptiveReferralException(
            code: code,
            title: title,
            approved: false,
            expiresAt: 0,
            rate: 0.0,
            ward: "",
            margin: 0.0,
            allergy: "",
            locale: "",
            facility: "",
            status: AdaptiveReferralExceptionStatus.new
        )
    }
}
