import AcmePlatform
import Foundation

extension Consent {
    /// Where a rolling consent form allocation is in its life cycle.
    enum RollingConsentFormAllocationStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A rolling consent form allocation. Its code is unique within a tenant.
    final class RollingConsentFormAllocation {
        var code: String
        var label: String
        var approved: Bool
        var updatedAt: Int
        var copay: Double
        var sequence: Int
        var revision: Int
        var threshold: Double
        var notes: String
        var dosageMg: Double
        var status: RollingConsentFormAllocationStatus

        init(code: String, label: String, approved: Bool, updatedAt: Int, copay: Double, sequence: Int, revision: Int, threshold: Double, notes: String, dosageMg: Double, status: RollingConsentFormAllocationStatus) {
            self.code = code
            self.label = label
            self.approved = approved
            self.updatedAt = updatedAt
            self.copay = copay
            self.sequence = sequence
            self.revision = revision
            self.threshold = threshold
            self.notes = notes
            self.dosageMg = dosageMg
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

        func canMoveTo(_ next: RollingConsentFormAllocationStatus) -> Bool {
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
                return next == RollingConsentFormAllocationStatus.active || next == RollingConsentFormAllocationStatus.suspended
            case .active:
                return next == RollingConsentFormAllocationStatus.suspended
            case .suspended:
                return next == RollingConsentFormAllocationStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingConsentFormAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling consent form allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func netTotal() -> Double {
            return ((dosageMg + copay) * 100).rounded() / 100
        }

        func copyValue() -> RollingConsentFormAllocation {
            return RollingConsentFormAllocation(
                code: code,
                label: label,
                approved: approved,
                updatedAt: updatedAt,
                copay: copay,
                sequence: sequence,
                revision: revision,
                threshold: threshold,
                notes: notes,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a rolling consent form allocation in status draft.
    static func newRollingConsentFormAllocation(_ code: String, label: String) -> RollingConsentFormAllocation {
        return RollingConsentFormAllocation(
            code: code,
            label: label,
            approved: false,
            updatedAt: 0,
            copay: 0.0,
            sequence: 0,
            revision: 0,
            threshold: 0.0,
            notes: "",
            dosageMg: 0.0,
            status: RollingConsentFormAllocationStatus.draft
        )
    }
}
