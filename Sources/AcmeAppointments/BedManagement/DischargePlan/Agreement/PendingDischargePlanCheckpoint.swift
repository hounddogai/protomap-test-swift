import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a pending discharge plan checkpoint is in its life cycle.
    enum PendingDischargePlanCheckpointStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A pending discharge plan checkpoint. Its code is unique within a tenant.
    final class PendingDischargePlanCheckpoint {
        var code: String
        var label: String
        var unit: String
        var copay: Double
        var version: Int
        var ceiling: Double
        var status: PendingDischargePlanCheckpointStatus

        init(code: String, label: String, unit: String, copay: Double, version: Int, ceiling: Double, status: PendingDischargePlanCheckpointStatus) {
            self.code = code
            self.label = label
            self.unit = unit
            self.copay = copay
            self.version = version
            self.ceiling = ceiling
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

        func canMoveTo(_ next: PendingDischargePlanCheckpointStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == PendingDischargePlanCheckpointStatus.failed
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: PendingDischargePlanCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending discharge plan checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\("pending discharge plan checkpoint") \(code)"
        }

        func effectiveExposure() -> Double {
            return ((Double(version) + ceiling) * 100).rounded() / 100
        }

        func copyValue() -> PendingDischargePlanCheckpoint {
            return PendingDischargePlanCheckpoint(
                code: code,
                label: label,
                unit: unit,
                copay: copay,
                version: version,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a pending discharge plan checkpoint in status new.
    static func newPendingDischargePlanCheckpoint(_ code: String, label: String) -> PendingDischargePlanCheckpoint {
        return PendingDischargePlanCheckpoint(
            code: code,
            label: label,
            unit: "",
            copay: 0.0,
            version: 0,
            ceiling: 0.0,
            status: PendingDischargePlanCheckpointStatus.new
        )
    }
}
