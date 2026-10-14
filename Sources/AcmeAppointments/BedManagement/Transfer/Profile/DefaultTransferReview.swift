import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a default transfer review is in its life cycle.
    enum DefaultTransferReviewStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a default transfer review and its current status.
    final class DefaultTransferReview {
        var code: String
        var name: String
        var ceiling: Double
        var timezone: String
        var startsAt: Int
        var ratio: Double
        var maximum: Double
        var checksum: String
        var title: String
        var copay: Double
        var status: DefaultTransferReviewStatus

        init(code: String, name: String, ceiling: Double, timezone: String, startsAt: Int, ratio: Double, maximum: Double, checksum: String, title: String, copay: Double, status: DefaultTransferReviewStatus) {
            self.code = code
            self.name = name
            self.ceiling = ceiling
            self.timezone = timezone
            self.startsAt = startsAt
            self.ratio = ratio
            self.maximum = maximum
            self.checksum = checksum
            self.title = title
            self.copay = copay
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

        func canMoveTo(_ next: DefaultTransferReviewStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved, .archived:
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
                return next == DefaultTransferReviewStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultTransferReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default transfer review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func adjustedExposure() -> Double {
            return (ratio * copay * 100).rounded() / 100
        }

        func copyValue() -> DefaultTransferReview {
            return DefaultTransferReview(
                code: code,
                name: name,
                ceiling: ceiling,
                timezone: timezone,
                startsAt: startsAt,
                ratio: ratio,
                maximum: maximum,
                checksum: checksum,
                title: title,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a default transfer review in status open.
    static func newDefaultTransferReview(_ code: String, name: String) -> DefaultTransferReview {
        return DefaultTransferReview(
            code: code,
            name: name,
            ceiling: 0.0,
            timezone: "",
            startsAt: 0,
            ratio: 0.0,
            maximum: 0.0,
            checksum: "",
            title: "",
            copay: 0.0,
            status: DefaultTransferReviewStatus.`open`
        )
    }
}
