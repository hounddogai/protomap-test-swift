import AcmePlatform
import Foundation

extension Labs {
    /// Where a accession review is in its life cycle.
    enum AccessionReviewStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A accession review. Its code is unique within a tenant.
    final class AccessionReview {
        var code: String
        var name: String
        var locale: String
        var region: String
        var summary: String
        var budget: Double
        var country: String
        var bed: String
        var status: AccessionReviewStatus

        init(code: String, name: String, locale: String, region: String, summary: String, budget: Double, country: String, bed: String, status: AccessionReviewStatus) {
            self.code = code
            self.name = name
            self.locale = locale
            self.region = region
            self.summary = summary
            self.budget = budget
            self.country = country
            self.bed = bed
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AccessionReviewStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: AccessionReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("accession review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func measuredValue() -> Double {
            return budget
        }

        func copyValue() -> AccessionReview {
            return AccessionReview(
                code: code,
                name: name,
                locale: locale,
                region: region,
                summary: summary,
                budget: budget,
                country: country,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a accession review in status open.
    static func newAccessionReview(_ code: String, name: String) -> AccessionReview {
        return AccessionReview(
            code: code,
            name: name,
            locale: "",
            region: "",
            summary: "",
            budget: 0.0,
            country: "",
            bed: "",
            status: AccessionReviewStatus.`open`
        )
    }
}
