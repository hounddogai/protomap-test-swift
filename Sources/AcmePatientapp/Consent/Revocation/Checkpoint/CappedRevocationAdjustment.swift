import AcmePlatform
import Foundation

extension Consent {
    /// Where a capped revocation adjustment is in its life cycle.
    enum CappedRevocationAdjustmentStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A capped revocation adjustment as the revocation team keeps it.
    final class CappedRevocationAdjustment {
        var code: String
        var label: String
        var allergy: String
        var ratio: Double
        var attempts: Int
        var pinned: Bool
        var status: CappedRevocationAdjustmentStatus

        init(code: String, label: String, allergy: String, ratio: Double, attempts: Int, pinned: Bool, status: CappedRevocationAdjustmentStatus) {
            self.code = code
            self.label = label
            self.allergy = allergy
            self.ratio = ratio
            self.attempts = attempts
            self.pinned = pinned
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

        func canMoveTo(_ next: CappedRevocationAdjustmentStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == CappedRevocationAdjustmentStatus.cancelled
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

        func moveTo(_ next: CappedRevocationAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped revocation adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func effectiveTotal() -> Double {
            return ((ratio + Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> CappedRevocationAdjustment {
            return CappedRevocationAdjustment(
                code: code,
                label: label,
                allergy: allergy,
                ratio: ratio,
                attempts: attempts,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a capped revocation adjustment in status planned.
    static func newCappedRevocationAdjustment(_ code: String, label: String) -> CappedRevocationAdjustment {
        return CappedRevocationAdjustment(
            code: code,
            label: label,
            allergy: "",
            ratio: 0.0,
            attempts: 0,
            pinned: false,
            status: CappedRevocationAdjustmentStatus.planned
        )
    }
}
