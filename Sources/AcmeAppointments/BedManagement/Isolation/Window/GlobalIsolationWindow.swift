import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a global isolation window is in its life cycle.
    enum GlobalIsolationWindowStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One global isolation window, with what the planners need to act on it.
    final class GlobalIsolationWindow {
        var code: String
        var label: String
        var revision: Int
        var dosageMg: Double
        var visitMinutes: Int
        var status: GlobalIsolationWindowStatus

        init(code: String, label: String, revision: Int, dosageMg: Double, visitMinutes: Int, status: GlobalIsolationWindowStatus) {
            self.code = code
            self.label = label
            self.revision = revision
            self.dosageMg = dosageMg
            self.visitMinutes = visitMinutes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: GlobalIsolationWindowStatus) -> Bool {
            switch status {
            case .created:
                return next == GlobalIsolationWindowStatus.validated || next == GlobalIsolationWindowStatus.retired
            case .validated:
                return next == GlobalIsolationWindowStatus.retired
            case .published:
                return next == GlobalIsolationWindowStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalIsolationWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global isolation window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func weightedValue() -> Double {
            return (dosageMg * Double(revision) * 100).rounded() / 100
        }

        func copyValue() -> GlobalIsolationWindow {
            return GlobalIsolationWindow(
                code: code,
                label: label,
                revision: revision,
                dosageMg: dosageMg,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a global isolation window in status created.
    static func newGlobalIsolationWindow(_ code: String, label: String) -> GlobalIsolationWindow {
        return GlobalIsolationWindow(
            code: code,
            label: label,
            revision: 0,
            dosageMg: 0.0,
            visitMinutes: 0,
            status: GlobalIsolationWindowStatus.created
        )
    }
}
