import AcmePlatform
import Foundation

extension Imaging {
    /// Where a regional study variance is in its life cycle.
    enum RegionalStudyVarianceStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One regional study variance, with what the planners need to act on it.
    final class RegionalStudyVariance {
        var code: String
        var title: String
        var visitMinutes: Int
        var graceDays: Int
        var ratio: Double
        var updatedAt: Int
        var archived: Bool
        var status: RegionalStudyVarianceStatus

        init(code: String, title: String, visitMinutes: Int, graceDays: Int, ratio: Double, updatedAt: Int, archived: Bool, status: RegionalStudyVarianceStatus) {
            self.code = code
            self.title = title
            self.visitMinutes = visitMinutes
            self.graceDays = graceDays
            self.ratio = ratio
            self.updatedAt = updatedAt
            self.archived = archived
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

        func canMoveTo(_ next: RegionalStudyVarianceStatus) -> Bool {
            switch status {
            case .`open`:
                return next == RegionalStudyVarianceStatus.inReview || next == RegionalStudyVarianceStatus.resolved
            case .inReview:
                return next == RegionalStudyVarianceStatus.resolved
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

        func moveTo(_ next: RegionalStudyVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional study variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("regional study variance") \(code)"
        }

        func effectiveLoad() -> Double {
            return ((Double(updatedAt) - ratio) * 100).rounded() / 100
        }

        func copyValue() -> RegionalStudyVariance {
            return RegionalStudyVariance(
                code: code,
                title: title,
                visitMinutes: visitMinutes,
                graceDays: graceDays,
                ratio: ratio,
                updatedAt: updatedAt,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a regional study variance in status open.
    static func newRegionalStudyVariance(_ code: String, title: String) -> RegionalStudyVariance {
        return RegionalStudyVariance(
            code: code,
            title: title,
            visitMinutes: 0,
            graceDays: 0,
            ratio: 0.0,
            updatedAt: 0,
            archived: false,
            status: RegionalStudyVarianceStatus.`open`
        )
    }
}
