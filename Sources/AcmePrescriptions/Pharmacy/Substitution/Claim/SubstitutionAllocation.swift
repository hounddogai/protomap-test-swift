import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a substitution allocation is in its life cycle.
    enum SubstitutionAllocationStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One substitution allocation, with what the planners need to act on it.
    final class SubstitutionAllocation {
        var code: String
        var label: String
        var dosageMg: Double
        var version: Int
        var payer: String
        var attempts: Int
        var status: SubstitutionAllocationStatus

        init(code: String, label: String, dosageMg: Double, version: Int, payer: String, attempts: Int, status: SubstitutionAllocationStatus) {
            self.code = code
            self.label = label
            self.dosageMg = dosageMg
            self.version = version
            self.payer = payer
            self.attempts = attempts
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SubstitutionAllocationStatus) -> Bool {
            switch status {
            case .`open`:
                return next == SubstitutionAllocationStatus.inReview || next == SubstitutionAllocationStatus.archived
            case .inReview:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: SubstitutionAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("substitution allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func weightedLoad() -> Double {
            return ((dosageMg - Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> SubstitutionAllocation {
            return SubstitutionAllocation(
                code: code,
                label: label,
                dosageMg: dosageMg,
                version: version,
                payer: payer,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a substitution allocation in status open.
    static func newSubstitutionAllocation(_ code: String, label: String) -> SubstitutionAllocation {
        return SubstitutionAllocation(
            code: code,
            label: label,
            dosageMg: 0.0,
            version: 0,
            payer: "",
            attempts: 0,
            status: SubstitutionAllocationStatus.`open`
        )
    }
}
