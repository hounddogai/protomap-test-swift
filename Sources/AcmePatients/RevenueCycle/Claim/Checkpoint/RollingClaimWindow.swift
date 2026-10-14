import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a rolling claim window is in its life cycle.
    enum RollingClaimWindowStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A rolling claim window as the claim team keeps it.
    final class RollingClaimWindow {
        var code: String
        var label: String
        var tags: [String]
        var ceiling: Double
        var source: String
        var status: RollingClaimWindowStatus

        init(code: String, label: String, tags: [String], ceiling: Double, source: String, status: RollingClaimWindowStatus) {
            self.code = code
            self.label = label
            self.tags = tags
            self.ceiling = ceiling
            self.source = source
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

        func canMoveTo(_ next: RollingClaimWindowStatus) -> Bool {
            switch status {
            case .draft:
                return next == RollingClaimWindowStatus.suspended || next == RollingClaimWindowStatus.closed
            case .pending:
                return next == RollingClaimWindowStatus.suspended || next == RollingClaimWindowStatus.closed
            case .active:
                return next == RollingClaimWindowStatus.suspended
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: RollingClaimWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling claim window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
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
            return ceiling
        }

        func copyValue() -> RollingClaimWindow {
            return RollingClaimWindow(
                code: code,
                label: label,
                tags: tags,
                ceiling: ceiling,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a rolling claim window in status draft.
    static func newRollingClaimWindow(_ code: String, label: String) -> RollingClaimWindow {
        return RollingClaimWindow(
            code: code,
            label: label,
            tags: [],
            ceiling: 0.0,
            source: "",
            status: RollingClaimWindowStatus.draft
        )
    }
}
