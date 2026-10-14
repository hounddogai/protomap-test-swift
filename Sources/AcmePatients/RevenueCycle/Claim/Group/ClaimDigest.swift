import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a claim digest is in its life cycle.
    enum ClaimDigestStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A claim digest. Its code is unique within a tenant.
    final class ClaimDigest {
        var code: String
        var label: String
        var dosageMg: Double
        var procedureCode: String
        var margin: Double
        var notes: String
        var maximum: Double
        var status: ClaimDigestStatus

        init(code: String, label: String, dosageMg: Double, procedureCode: String, margin: Double, notes: String, maximum: Double, status: ClaimDigestStatus) {
            self.code = code
            self.label = label
            self.dosageMg = dosageMg
            self.procedureCode = procedureCode
            self.margin = margin
            self.notes = notes
            self.maximum = maximum
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

        func canMoveTo(_ next: ClaimDigestStatus) -> Bool {
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
                return next == ClaimDigestStatus.closed
            case .active:
                return next == ClaimDigestStatus.suspended
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

        func moveTo(_ next: ClaimDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("claim digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func projectedValue() -> Double {
            return ((dosageMg - margin) * 100).rounded() / 100
        }

        func copyValue() -> ClaimDigest {
            return ClaimDigest(
                code: code,
                label: label,
                dosageMg: dosageMg,
                procedureCode: procedureCode,
                margin: margin,
                notes: notes,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a claim digest in status draft.
    static func newClaimDigest(_ code: String, label: String) -> ClaimDigest {
        return ClaimDigest(
            code: code,
            label: label,
            dosageMg: 0.0,
            procedureCode: "",
            margin: 0.0,
            notes: "",
            maximum: 0.0,
            status: ClaimDigestStatus.draft
        )
    }
}
