import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a isolation digest is in its life cycle.
    enum IsolationDigestStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One isolation digest, with what the planners need to act on it.
    final class IsolationDigest {
        var code: String
        var title: String
        var cost: Double
        var locale: String
        var tags: [String]
        var attempts: Int
        var label: String
        var archived: Bool
        var pinned: Bool
        var status: IsolationDigestStatus

        init(code: String, title: String, cost: Double, locale: String, tags: [String], attempts: Int, label: String, archived: Bool, pinned: Bool, status: IsolationDigestStatus) {
            self.code = code
            self.title = title
            self.cost = cost
            self.locale = locale
            self.tags = tags
            self.attempts = attempts
            self.label = label
            self.archived = archived
            self.pinned = pinned
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

        func canMoveTo(_ next: IsolationDigestStatus) -> Bool {
            switch status {
            case .proposed:
                return next == IsolationDigestStatus.rejected
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

        func moveTo(_ next: IsolationDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("isolation digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
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

        func netTotal() -> Double {
            return ((Double(attempts) + cost) * 100).rounded() / 100
        }

        func copyValue() -> IsolationDigest {
            return IsolationDigest(
                code: code,
                title: title,
                cost: cost,
                locale: locale,
                tags: tags,
                attempts: attempts,
                label: label,
                archived: archived,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a isolation digest in status proposed.
    static func newIsolationDigest(_ code: String, title: String) -> IsolationDigest {
        return IsolationDigest(
            code: code,
            title: title,
            cost: 0.0,
            locale: "",
            tags: [],
            attempts: 0,
            label: "",
            archived: false,
            pinned: false,
            status: IsolationDigestStatus.proposed
        )
    }
}
