import AcmePlatform
import Foundation

extension Consent {
    /// Where a rolling consent form segment is in its life cycle.
    enum RollingConsentFormSegmentStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One rolling consent form segment, with what the planners need to act on it.
    final class RollingConsentFormSegment {
        var code: String
        var label: String
        var checksum: String
        var revision: Int
        var title: String
        var name: String
        var category: String
        var ownerID: String
        var status: RollingConsentFormSegmentStatus

        init(code: String, label: String, checksum: String, revision: Int, title: String, name: String, category: String, ownerID: String, status: RollingConsentFormSegmentStatus) {
            self.code = code
            self.label = label
            self.checksum = checksum
            self.revision = revision
            self.title = title
            self.name = name
            self.category = category
            self.ownerID = ownerID
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

        func canMoveTo(_ next: RollingConsentFormSegmentStatus) -> Bool {
            switch status {
            case .`open`:
                return next == RollingConsentFormSegmentStatus.inReview || next == RollingConsentFormSegmentStatus.reopened
            case .inReview:
                switch next {
                case .resolved, .reopened:
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
                return next == RollingConsentFormSegmentStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingConsentFormSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling consent form segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func measuredValue() -> Double {
            return Double(revision)
        }

        func copyValue() -> RollingConsentFormSegment {
            return RollingConsentFormSegment(
                code: code,
                label: label,
                checksum: checksum,
                revision: revision,
                title: title,
                name: name,
                category: category,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a rolling consent form segment in status open.
    static func newRollingConsentFormSegment(_ code: String, label: String) -> RollingConsentFormSegment {
        return RollingConsentFormSegment(
            code: code,
            label: label,
            checksum: "",
            revision: 0,
            title: "",
            name: "",
            category: "",
            ownerID: "",
            status: RollingConsentFormSegmentStatus.`open`
        )
    }
}
