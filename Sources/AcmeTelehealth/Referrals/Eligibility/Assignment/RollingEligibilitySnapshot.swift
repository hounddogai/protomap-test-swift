import AcmePlatform
import Foundation

extension Referrals {
    /// Where a rolling eligibility snapshot is in its life cycle.
    enum RollingEligibilitySnapshotStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A rolling eligibility snapshot as the eligibility team keeps it.
    final class RollingEligibilitySnapshot {
        var code: String
        var name: String
        var checksum: String
        var patientRef: String
        var source: String
        var amount: Double
        var status: RollingEligibilitySnapshotStatus

        init(code: String, name: String, checksum: String, patientRef: String, source: String, amount: Double, status: RollingEligibilitySnapshotStatus) {
            self.code = code
            self.name = name
            self.checksum = checksum
            self.patientRef = patientRef
            self.source = source
            self.amount = amount
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

        func canMoveTo(_ next: RollingEligibilitySnapshotStatus) -> Bool {
            switch status {
            case .created:
                return next == RollingEligibilitySnapshotStatus.retired
            case .validated:
                return next == RollingEligibilitySnapshotStatus.published
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: RollingEligibilitySnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling eligibility snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> RollingEligibilitySnapshot {
            return RollingEligibilitySnapshot(
                code: code,
                name: name,
                checksum: checksum,
                patientRef: patientRef,
                source: source,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a rolling eligibility snapshot in status created.
    static func newRollingEligibilitySnapshot(_ code: String, name: String) -> RollingEligibilitySnapshot {
        return RollingEligibilitySnapshot(
            code: code,
            name: name,
            checksum: "",
            patientRef: "",
            source: "",
            amount: 0.0,
            status: RollingEligibilitySnapshotStatus.created
        )
    }
}
