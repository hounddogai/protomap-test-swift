import AcmePlatform
import Foundation

extension Consent {
    /// Where a revocation digest is in its life cycle.
    enum RevocationDigestStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a revocation digest and its current status.
    final class RevocationDigest {
        var code: String
        var title: String
        var acuity: Int
        var segment: String
        var phone: String
        var margin: Double
        var reviewer: String
        var tags: [String]
        var status: RevocationDigestStatus

        init(code: String, title: String, acuity: Int, segment: String, phone: String, margin: Double, reviewer: String, tags: [String], status: RevocationDigestStatus) {
            self.code = code
            self.title = title
            self.acuity = acuity
            self.segment = segment
            self.phone = phone
            self.margin = margin
            self.reviewer = reviewer
            self.tags = tags
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RevocationDigestStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == RevocationDigestStatus.cancelled
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: RevocationDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("revocation digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedLoad() -> Double {
            return ((margin - Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> RevocationDigest {
            return RevocationDigest(
                code: code,
                title: title,
                acuity: acuity,
                segment: segment,
                phone: phone,
                margin: margin,
                reviewer: reviewer,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a revocation digest in status planned.
    static func newRevocationDigest(_ code: String, title: String) -> RevocationDigest {
        return RevocationDigest(
            code: code,
            title: title,
            acuity: 0,
            segment: "",
            phone: "",
            margin: 0.0,
            reviewer: "",
            tags: [],
            status: RevocationDigestStatus.planned
        )
    }
}
