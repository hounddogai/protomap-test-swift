import AcmePlatform
import Foundation

extension Referrals {
    /// Where a follow up segment is in its life cycle.
    enum FollowUpSegmentStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A follow up segment. Its code is unique within a tenant.
    final class FollowUpSegment {
        var code: String
        var title: String
        var facility: String
        var ratio: Double
        var discount: Double
        var channel: String
        var tags: [String]
        var status: FollowUpSegmentStatus

        init(code: String, title: String, facility: String, ratio: Double, discount: Double, channel: String, tags: [String], status: FollowUpSegmentStatus) {
            self.code = code
            self.title = title
            self.facility = facility
            self.ratio = ratio
            self.discount = discount
            self.channel = channel
            self.tags = tags
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

        func canMoveTo(_ next: FollowUpSegmentStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .resolved:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .archived:
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

        func moveTo(_ next: FollowUpSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("follow up segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func projectedValue() -> Double {
            return ((ratio + discount) * 100).rounded() / 100
        }

        func copyValue() -> FollowUpSegment {
            return FollowUpSegment(
                code: code,
                title: title,
                facility: facility,
                ratio: ratio,
                discount: discount,
                channel: channel,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a follow up segment in status open.
    static func newFollowUpSegment(_ code: String, title: String) -> FollowUpSegment {
        return FollowUpSegment(
            code: code,
            title: title,
            facility: "",
            ratio: 0.0,
            discount: 0.0,
            channel: "",
            tags: [],
            status: FollowUpSegmentStatus.`open`
        )
    }
}
