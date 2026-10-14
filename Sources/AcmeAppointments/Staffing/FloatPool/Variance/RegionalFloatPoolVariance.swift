import AcmePlatform
import Foundation

extension Staffing {
    /// Where a regional float pool variance is in its life cycle.
    enum RegionalFloatPoolVarianceStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A regional float pool variance as the float pool team keeps it.
    final class RegionalFloatPoolVariance {
        var code: String
        var title: String
        var summary: String
        var limit: Int
        var rate: Double
        var status: RegionalFloatPoolVarianceStatus

        init(code: String, title: String, summary: String, limit: Int, rate: Double, status: RegionalFloatPoolVarianceStatus) {
            self.code = code
            self.title = title
            self.summary = summary
            self.limit = limit
            self.rate = rate
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

        func canMoveTo(_ next: RegionalFloatPoolVarianceStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .archived:
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
                return next == RegionalFloatPoolVarianceStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalFloatPoolVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional float pool variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func netTotal() -> Double {
            return (rate * Double(limit) * 100).rounded() / 100
        }

        func copyValue() -> RegionalFloatPoolVariance {
            return RegionalFloatPoolVariance(
                code: code,
                title: title,
                summary: summary,
                limit: limit,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a regional float pool variance in status open.
    static func newRegionalFloatPoolVariance(_ code: String, title: String) -> RegionalFloatPoolVariance {
        return RegionalFloatPoolVariance(
            code: code,
            title: title,
            summary: "",
            limit: 0,
            rate: 0.0,
            status: RegionalFloatPoolVarianceStatus.`open`
        )
    }
}
