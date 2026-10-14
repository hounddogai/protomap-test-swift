import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a manual program window is in its life cycle.
    enum ManualProgramWindowStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a manual program window and its current status.
    final class ManualProgramWindow {
        var code: String
        var title: String
        var attempts: Int
        var priority: Int
        var acuity: Int
        var maximum: Double
        var expiresAt: Int
        var status: ManualProgramWindowStatus

        init(code: String, title: String, attempts: Int, priority: Int, acuity: Int, maximum: Double, expiresAt: Int, status: ManualProgramWindowStatus) {
            self.code = code
            self.title = title
            self.attempts = attempts
            self.priority = priority
            self.acuity = acuity
            self.maximum = maximum
            self.expiresAt = expiresAt
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

        func canMoveTo(_ next: ManualProgramWindowStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .closed:
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
                return next == ManualProgramWindowStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualProgramWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual program window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func effectiveExposure() -> Double {
            return (Double(acuity) * Double(expiresAt) * 100).rounded() / 100
        }

        func copyValue() -> ManualProgramWindow {
            return ManualProgramWindow(
                code: code,
                title: title,
                attempts: attempts,
                priority: priority,
                acuity: acuity,
                maximum: maximum,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a manual program window in status draft.
    static func newManualProgramWindow(_ code: String, title: String) -> ManualProgramWindow {
        return ManualProgramWindow(
            code: code,
            title: title,
            attempts: 0,
            priority: 0,
            acuity: 0,
            maximum: 0.0,
            expiresAt: 0,
            status: ManualProgramWindowStatus.draft
        )
    }
}
