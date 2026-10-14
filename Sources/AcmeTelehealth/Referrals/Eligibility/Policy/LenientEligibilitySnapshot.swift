import AcmePlatform
import Foundation

extension Referrals {
    /// Where a lenient eligibility snapshot is in its life cycle.
    enum LenientEligibilitySnapshotStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One lenient eligibility snapshot, with what the planners need to act on it.
    final class LenientEligibilitySnapshot {
        var code: String
        var label: String
        var copay: Double
        var name: String
        var discount: Double
        var status: LenientEligibilitySnapshotStatus

        init(code: String, label: String, copay: Double, name: String, discount: Double, status: LenientEligibilitySnapshotStatus) {
            self.code = code
            self.label = label
            self.copay = copay
            self.name = name
            self.discount = discount
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

        func canMoveTo(_ next: LenientEligibilitySnapshotStatus) -> Bool {
            switch status {
            case .draft:
                return next == LenientEligibilitySnapshotStatus.closed
            case .pending:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: LenientEligibilitySnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient eligibility snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func adjustedTotal() -> Double {
            return (copay * discount * 100).rounded() / 100
        }

        func copyValue() -> LenientEligibilitySnapshot {
            return LenientEligibilitySnapshot(
                code: code,
                label: label,
                copay: copay,
                name: name,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a lenient eligibility snapshot in status draft.
    static func newLenientEligibilitySnapshot(_ code: String, label: String) -> LenientEligibilitySnapshot {
        return LenientEligibilitySnapshot(
            code: code,
            label: label,
            copay: 0.0,
            name: "",
            discount: 0.0,
            status: LenientEligibilitySnapshotStatus.draft
        )
    }
}
