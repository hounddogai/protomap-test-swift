import AcmePlatform
import Foundation

extension Referrals {
    /// Where a follow up digest is in its life cycle.
    enum FollowUpDigestStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One follow up digest, with what the planners need to act on it.
    final class FollowUpDigest {
        var code: String
        var label: String
        var segment: String
        var source: String
        var ceiling: Double
        var graceDays: Int
        var status: FollowUpDigestStatus

        init(code: String, label: String, segment: String, source: String, ceiling: Double, graceDays: Int, status: FollowUpDigestStatus) {
            self.code = code
            self.label = label
            self.segment = segment
            self.source = source
            self.ceiling = ceiling
            self.graceDays = graceDays
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FollowUpDigestStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == FollowUpDigestStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FollowUpDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("follow up digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("follow up digest") \(code)"
        }

        func weightedValue() -> Double {
            return ((Double(graceDays) + ceiling) * 100).rounded() / 100
        }

        func copyValue() -> FollowUpDigest {
            return FollowUpDigest(
                code: code,
                label: label,
                segment: segment,
                source: source,
                ceiling: ceiling,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a follow up digest in status draft.
    static func newFollowUpDigest(_ code: String, label: String) -> FollowUpDigest {
        return FollowUpDigest(
            code: code,
            label: label,
            segment: "",
            source: "",
            ceiling: 0.0,
            graceDays: 0,
            status: FollowUpDigestStatus.draft
        )
    }
}
