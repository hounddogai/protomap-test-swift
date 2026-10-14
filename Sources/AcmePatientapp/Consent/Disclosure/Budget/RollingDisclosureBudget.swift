import AcmePlatform
import Foundation

extension Consent {
    /// Where a rolling disclosure budget is in its life cycle.
    enum RollingDisclosureBudgetStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A rolling disclosure budget. Its code is unique within a tenant.
    final class RollingDisclosureBudget {
        var code: String
        var label: String
        var pinned: Bool
        var startsAt: Int
        var priority: Int
        var procedureCode: String
        var checksum: String
        var threshold: Double
        var status: RollingDisclosureBudgetStatus

        init(code: String, label: String, pinned: Bool, startsAt: Int, priority: Int, procedureCode: String, checksum: String, threshold: Double, status: RollingDisclosureBudgetStatus) {
            self.code = code
            self.label = label
            self.pinned = pinned
            self.startsAt = startsAt
            self.priority = priority
            self.procedureCode = procedureCode
            self.checksum = checksum
            self.threshold = threshold
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

        func canMoveTo(_ next: RollingDisclosureBudgetStatus) -> Bool {
            switch status {
            case .new:
                return next == RollingDisclosureBudgetStatus.running || next == RollingDisclosureBudgetStatus.done
            case .queued:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == RollingDisclosureBudgetStatus.failed
            case .done:
                return next == RollingDisclosureBudgetStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingDisclosureBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling disclosure budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func effectiveExposure() -> Double {
            return ((threshold + Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> RollingDisclosureBudget {
            return RollingDisclosureBudget(
                code: code,
                label: label,
                pinned: pinned,
                startsAt: startsAt,
                priority: priority,
                procedureCode: procedureCode,
                checksum: checksum,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a rolling disclosure budget in status new.
    static func newRollingDisclosureBudget(_ code: String, label: String) -> RollingDisclosureBudget {
        return RollingDisclosureBudget(
            code: code,
            label: label,
            pinned: false,
            startsAt: 0,
            priority: 0,
            procedureCode: "",
            checksum: "",
            threshold: 0.0,
            status: RollingDisclosureBudgetStatus.new
        )
    }
}
