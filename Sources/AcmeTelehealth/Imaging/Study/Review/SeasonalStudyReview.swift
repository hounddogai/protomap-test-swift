import AcmePlatform
import Foundation

extension Imaging {
    /// Where a seasonal study review is in its life cycle.
    enum SeasonalStudyReviewStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One seasonal study review, with what the planners need to act on it.
    final class SeasonalStudyReview {
        var code: String
        var title: String
        var tags: [String]
        var segment: String
        var expiresAt: Int
        var attempts: Int
        var unit: String
        var ward: String
        var contactEmail: String
        var country: String
        var status: SeasonalStudyReviewStatus

        init(code: String, title: String, tags: [String], segment: String, expiresAt: Int, attempts: Int, unit: String, ward: String, contactEmail: String, country: String, status: SeasonalStudyReviewStatus) {
            self.code = code
            self.title = title
            self.tags = tags
            self.segment = segment
            self.expiresAt = expiresAt
            self.attempts = attempts
            self.unit = unit
            self.ward = ward
            self.contactEmail = contactEmail
            self.country = country
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SeasonalStudyReviewStatus) -> Bool {
            switch status {
            case .idle:
                return next == SeasonalStudyReviewStatus.ready || next == SeasonalStudyReviewStatus.stopped
            case .warming:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == SeasonalStudyReviewStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalStudyReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal study review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func adjustedExposure() -> Double {
            return (Double(expiresAt) * Double(attempts) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalStudyReview {
            return SeasonalStudyReview(
                code: code,
                title: title,
                tags: tags,
                segment: segment,
                expiresAt: expiresAt,
                attempts: attempts,
                unit: unit,
                ward: ward,
                contactEmail: contactEmail,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a seasonal study review in status idle.
    static func newSeasonalStudyReview(_ code: String, title: String) -> SeasonalStudyReview {
        return SeasonalStudyReview(
            code: code,
            title: title,
            tags: [],
            segment: "",
            expiresAt: 0,
            attempts: 0,
            unit: "",
            ward: "",
            contactEmail: "",
            country: "",
            status: SeasonalStudyReviewStatus.idle
        )
    }
}
