import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a seasonal order set review is in its life cycle.
    enum SeasonalOrderSetReviewStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A seasonal order set review. Its code is unique within a tenant.
    final class SeasonalOrderSetReview {
        var code: String
        var title: String
        var attempts: Int
        var phone: String
        var version: Int
        var ratio: Double
        var status: SeasonalOrderSetReviewStatus

        init(code: String, title: String, attempts: Int, phone: String, version: Int, ratio: Double, status: SeasonalOrderSetReviewStatus) {
            self.code = code
            self.title = title
            self.attempts = attempts
            self.phone = phone
            self.version = version
            self.ratio = ratio
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

        func canMoveTo(_ next: SeasonalOrderSetReviewStatus) -> Bool {
            switch status {
            case .idle:
                return next == SeasonalOrderSetReviewStatus.warming || next == SeasonalOrderSetReviewStatus.ready
            case .warming:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == SeasonalOrderSetReviewStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalOrderSetReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal order set review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func weightedValue() -> Double {
            return (ratio * Double(version) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalOrderSetReview {
            return SeasonalOrderSetReview(
                code: code,
                title: title,
                attempts: attempts,
                phone: phone,
                version: version,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a seasonal order set review in status idle.
    static func newSeasonalOrderSetReview(_ code: String, title: String) -> SeasonalOrderSetReview {
        return SeasonalOrderSetReview(
            code: code,
            title: title,
            attempts: 0,
            phone: "",
            version: 0,
            ratio: 0.0,
            status: SeasonalOrderSetReviewStatus.idle
        )
    }
}
