import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a fallback denial review is in its life cycle.
    enum FallbackDenialReviewStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One fallback denial review, with what the planners need to act on it.
    final class FallbackDenialReview {
        var code: String
        var label: String
        var currency: String
        var encounterID: String
        var country: String
        var bed: String
        var durationMinutes: Int
        var allergy: String
        var maximum: Double
        var status: FallbackDenialReviewStatus

        init(code: String, label: String, currency: String, encounterID: String, country: String, bed: String, durationMinutes: Int, allergy: String, maximum: Double, status: FallbackDenialReviewStatus) {
            self.code = code
            self.label = label
            self.currency = currency
            self.encounterID = encounterID
            self.country = country
            self.bed = bed
            self.durationMinutes = durationMinutes
            self.allergy = allergy
            self.maximum = maximum
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FallbackDenialReviewStatus) -> Bool {
            switch status {
            case .requested:
                return next == FallbackDenialReviewStatus.revoked || next == FallbackDenialReviewStatus.expired
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == FallbackDenialReviewStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackDenialReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback denial review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func netLoad() -> Double {
            return ((maximum - Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> FallbackDenialReview {
            return FallbackDenialReview(
                code: code,
                label: label,
                currency: currency,
                encounterID: encounterID,
                country: country,
                bed: bed,
                durationMinutes: durationMinutes,
                allergy: allergy,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a fallback denial review in status requested.
    static func newFallbackDenialReview(_ code: String, label: String) -> FallbackDenialReview {
        return FallbackDenialReview(
            code: code,
            label: label,
            currency: "",
            encounterID: "",
            country: "",
            bed: "",
            durationMinutes: 0,
            allergy: "",
            maximum: 0.0,
            status: FallbackDenialReviewStatus.requested
        )
    }
}
