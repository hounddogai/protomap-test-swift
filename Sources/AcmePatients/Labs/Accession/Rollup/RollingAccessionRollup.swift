import AcmePlatform
import Foundation

extension Labs {
    /// Where a rolling accession rollup is in its life cycle.
    enum RollingAccessionRollupStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One rolling accession rollup, with what the planners need to act on it.
    final class RollingAccessionRollup {
        var code: String
        var name: String
        var externalRef: String
        var visible: Bool
        var tags: [String]
        var active: Bool
        var contactEmail: String
        var amount: Double
        var status: RollingAccessionRollupStatus

        init(code: String, name: String, externalRef: String, visible: Bool, tags: [String], active: Bool, contactEmail: String, amount: Double, status: RollingAccessionRollupStatus) {
            self.code = code
            self.name = name
            self.externalRef = externalRef
            self.visible = visible
            self.tags = tags
            self.active = active
            self.contactEmail = contactEmail
            self.amount = amount
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

        func canMoveTo(_ next: RollingAccessionRollupStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == RollingAccessionRollupStatus.completed || next == RollingAccessionRollupStatus.cancelled
            case .inProgress:
                return next == RollingAccessionRollupStatus.completed
            case .completed:
                return next == RollingAccessionRollupStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingAccessionRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling accession rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> RollingAccessionRollup {
            return RollingAccessionRollup(
                code: code,
                name: name,
                externalRef: externalRef,
                visible: visible,
                tags: tags,
                active: active,
                contactEmail: contactEmail,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a rolling accession rollup in status planned.
    static func newRollingAccessionRollup(_ code: String, name: String) -> RollingAccessionRollup {
        return RollingAccessionRollup(
            code: code,
            name: name,
            externalRef: "",
            visible: false,
            tags: [],
            active: false,
            contactEmail: "",
            amount: 0.0,
            status: RollingAccessionRollupStatus.planned
        )
    }
}
