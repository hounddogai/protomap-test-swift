import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a task adjustment is in its life cycle.
    enum TaskAdjustmentStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A task adjustment as the task team keeps it.
    final class TaskAdjustment {
        var code: String
        var label: String
        var graceDays: Int
        var refills: Int
        var externalRef: String
        var country: String
        var retries: Int
        var payer: String
        var status: TaskAdjustmentStatus

        init(code: String, label: String, graceDays: Int, refills: Int, externalRef: String, country: String, retries: Int, payer: String, status: TaskAdjustmentStatus) {
            self.code = code
            self.label = label
            self.graceDays = graceDays
            self.refills = refills
            self.externalRef = externalRef
            self.country = country
            self.retries = retries
            self.payer = payer
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TaskAdjustmentStatus) -> Bool {
            switch status {
            case .new:
                return next == TaskAdjustmentStatus.queued
            case .queued:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == TaskAdjustmentStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TaskAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("task adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func effectiveVolume() -> Double {
            return ((Double(graceDays) + Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> TaskAdjustment {
            return TaskAdjustment(
                code: code,
                label: label,
                graceDays: graceDays,
                refills: refills,
                externalRef: externalRef,
                country: country,
                retries: retries,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a task adjustment in status new.
    static func newTaskAdjustment(_ code: String, label: String) -> TaskAdjustment {
        return TaskAdjustment(
            code: code,
            label: label,
            graceDays: 0,
            refills: 0,
            externalRef: "",
            country: "",
            retries: 0,
            payer: "",
            status: TaskAdjustmentStatus.new
        )
    }
}
