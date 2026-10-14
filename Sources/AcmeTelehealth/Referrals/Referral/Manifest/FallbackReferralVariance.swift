import AcmePlatform
import Foundation

extension Referrals {
    /// Where a fallback referral variance is in its life cycle.
    enum FallbackReferralVarianceStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One fallback referral variance, with what the planners need to act on it.
    final class FallbackReferralVariance {
        var code: String
        var title: String
        var floorValue: Double
        var ward: String
        var checksum: String
        var phone: String
        var score: Double
        var label: String
        var attributes: [String: String]
        var locale: String
        var status: FallbackReferralVarianceStatus

        init(code: String, title: String, floorValue: Double, ward: String, checksum: String, phone: String, score: Double, label: String, attributes: [String: String], locale: String, status: FallbackReferralVarianceStatus) {
            self.code = code
            self.title = title
            self.floorValue = floorValue
            self.ward = ward
            self.checksum = checksum
            self.phone = phone
            self.score = score
            self.label = label
            self.attributes = attributes
            self.locale = locale
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

        func canMoveTo(_ next: FallbackReferralVarianceStatus) -> Bool {
            switch status {
            case .new:
                return next == FallbackReferralVarianceStatus.done || next == FallbackReferralVarianceStatus.failed
            case .queued:
                return next == FallbackReferralVarianceStatus.running || next == FallbackReferralVarianceStatus.failed
            case .running:
                return next == FallbackReferralVarianceStatus.done || next == FallbackReferralVarianceStatus.failed
            case .done:
                return next == FallbackReferralVarianceStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackReferralVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback referral variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(title)"
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

        func weightedExposure() -> Double {
            return ((score - floorValue) * 100).rounded() / 100
        }

        func copyValue() -> FallbackReferralVariance {
            return FallbackReferralVariance(
                code: code,
                title: title,
                floorValue: floorValue,
                ward: ward,
                checksum: checksum,
                phone: phone,
                score: score,
                label: label,
                attributes: attributes,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a fallback referral variance in status new.
    static func newFallbackReferralVariance(_ code: String, title: String) -> FallbackReferralVariance {
        return FallbackReferralVariance(
            code: code,
            title: title,
            floorValue: 0.0,
            ward: "",
            checksum: "",
            phone: "",
            score: 0.0,
            label: "",
            attributes: [:],
            locale: "",
            status: FallbackReferralVarianceStatus.new
        )
    }
}
