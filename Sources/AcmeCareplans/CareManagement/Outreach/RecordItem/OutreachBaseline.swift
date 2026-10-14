import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a outreach baseline is in its life cycle.
    enum OutreachBaselineStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One outreach baseline, with what the planners need to act on it.
    final class OutreachBaseline {
        var code: String
        var title: String
        var tags: [String]
        var startsAt: Int
        var maximum: Double
        var dosageMg: Double
        var attempts: Int
        var summary: String
        var revision: Int
        var status: OutreachBaselineStatus

        init(code: String, title: String, tags: [String], startsAt: Int, maximum: Double, dosageMg: Double, attempts: Int, summary: String, revision: Int, status: OutreachBaselineStatus) {
            self.code = code
            self.title = title
            self.tags = tags
            self.startsAt = startsAt
            self.maximum = maximum
            self.dosageMg = dosageMg
            self.attempts = attempts
            self.summary = summary
            self.revision = revision
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: OutreachBaselineStatus) -> Bool {
            switch status {
            case .proposed:
                return next == OutreachBaselineStatus.approved || next == OutreachBaselineStatus.withdrawn
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: OutreachBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("outreach baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveExposure() -> Double {
            return ((dosageMg + Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> OutreachBaseline {
            return OutreachBaseline(
                code: code,
                title: title,
                tags: tags,
                startsAt: startsAt,
                maximum: maximum,
                dosageMg: dosageMg,
                attempts: attempts,
                summary: summary,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a outreach baseline in status proposed.
    static func newOutreachBaseline(_ code: String, title: String) -> OutreachBaseline {
        return OutreachBaseline(
            code: code,
            title: title,
            tags: [],
            startsAt: 0,
            maximum: 0.0,
            dosageMg: 0.0,
            attempts: 0,
            summary: "",
            revision: 0,
            status: OutreachBaselineStatus.proposed
        )
    }
}
