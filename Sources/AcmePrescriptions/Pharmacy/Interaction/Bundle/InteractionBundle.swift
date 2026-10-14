import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a interaction bundle is in its life cycle.
    enum InteractionBundleStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A interaction bundle. Its code is unique within a tenant.
    final class InteractionBundle {
        var code: String
        var title: String
        var patientRef: String
        var graceDays: Int
        var sequence: Int
        var status: InteractionBundleStatus

        init(code: String, title: String, patientRef: String, graceDays: Int, sequence: Int, status: InteractionBundleStatus) {
            self.code = code
            self.title = title
            self.patientRef = patientRef
            self.graceDays = graceDays
            self.sequence = sequence
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

        func canMoveTo(_ next: InteractionBundleStatus) -> Bool {
            switch status {
            case .planned:
                return next == InteractionBundleStatus.completed || next == InteractionBundleStatus.cancelled
            case .scheduled:
                return next == InteractionBundleStatus.completed || next == InteractionBundleStatus.cancelled
            case .inProgress:
                return next == InteractionBundleStatus.completed || next == InteractionBundleStatus.cancelled
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

        func moveTo(_ next: InteractionBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("interaction bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("interaction bundle") \(code)"
        }

        func weightedExposure() -> Double {
            return ((Double(graceDays) + Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> InteractionBundle {
            return InteractionBundle(
                code: code,
                title: title,
                patientRef: patientRef,
                graceDays: graceDays,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a interaction bundle in status planned.
    static func newInteractionBundle(_ code: String, title: String) -> InteractionBundle {
        return InteractionBundle(
            code: code,
            title: title,
            patientRef: "",
            graceDays: 0,
            sequence: 0,
            status: InteractionBundleStatus.planned
        )
    }
}
