import AcmePlatform
import Foundation

extension Consent {
    /// Where a language review is in its life cycle.
    enum LanguageReviewStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a language review and its current status.
    final class LanguageReview {
        var code: String
        var name: String
        var archived: Bool
        var region: String
        var category: String
        var timezone: String
        var maximum: Double
        var allergy: String
        var status: LanguageReviewStatus

        init(code: String, name: String, archived: Bool, region: String, category: String, timezone: String, maximum: Double, allergy: String, status: LanguageReviewStatus) {
            self.code = code
            self.name = name
            self.archived = archived
            self.region = region
            self.category = category
            self.timezone = timezone
            self.maximum = maximum
            self.allergy = allergy
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

        func canMoveTo(_ next: LanguageReviewStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == LanguageReviewStatus.revoked || next == LanguageReviewStatus.expired
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: LanguageReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("language review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("language review") \(code)"
        }

        func measuredValue() -> Double {
            return maximum
        }

        func copyValue() -> LanguageReview {
            return LanguageReview(
                code: code,
                name: name,
                archived: archived,
                region: region,
                category: category,
                timezone: timezone,
                maximum: maximum,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a language review in status requested.
    static func newLanguageReview(_ code: String, name: String) -> LanguageReview {
        return LanguageReview(
            code: code,
            name: name,
            archived: false,
            region: "",
            category: "",
            timezone: "",
            maximum: 0.0,
            allergy: "",
            status: LanguageReviewStatus.requested
        )
    }
}
