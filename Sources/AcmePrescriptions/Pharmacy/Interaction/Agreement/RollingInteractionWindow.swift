import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a rolling interaction window is in its life cycle.
    enum RollingInteractionWindowStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A rolling interaction window as the interaction team keeps it.
    final class RollingInteractionWindow {
        var code: String
        var title: String
        var source: String
        var expiresAt: Int
        var margin: Double
        var sequence: Int
        var status: RollingInteractionWindowStatus

        init(code: String, title: String, source: String, expiresAt: Int, margin: Double, sequence: Int, status: RollingInteractionWindowStatus) {
            self.code = code
            self.title = title
            self.source = source
            self.expiresAt = expiresAt
            self.margin = margin
            self.sequence = sequence
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

        func canMoveTo(_ next: RollingInteractionWindowStatus) -> Bool {
            switch status {
            case .draft:
                return next == RollingInteractionWindowStatus.suspended || next == RollingInteractionWindowStatus.closed
            case .pending:
                return next == RollingInteractionWindowStatus.suspended
            case .active:
                return next == RollingInteractionWindowStatus.suspended || next == RollingInteractionWindowStatus.closed
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

        func moveTo(_ next: RollingInteractionWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling interaction window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func projectedLoad() -> Double {
            return ((Double(sequence) - Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> RollingInteractionWindow {
            return RollingInteractionWindow(
                code: code,
                title: title,
                source: source,
                expiresAt: expiresAt,
                margin: margin,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a rolling interaction window in status draft.
    static func newRollingInteractionWindow(_ code: String, title: String) -> RollingInteractionWindow {
        return RollingInteractionWindow(
            code: code,
            title: title,
            source: "",
            expiresAt: 0,
            margin: 0.0,
            sequence: 0,
            status: RollingInteractionWindowStatus.draft
        )
    }
}
