import AcmePlatform
import Foundation

extension Labs {
    /// Where a reference range policy is in its life cycle.
    enum ReferenceRangePolicyStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A reference range policy as the reference range team keeps it.
    final class ReferenceRangePolicy {
        var code: String
        var label: String
        var patientRef: String
        var sequence: Int
        var minimum: Double
        var checksum: String
        var status: ReferenceRangePolicyStatus

        init(code: String, label: String, patientRef: String, sequence: Int, minimum: Double, checksum: String, status: ReferenceRangePolicyStatus) {
            self.code = code
            self.label = label
            self.patientRef = patientRef
            self.sequence = sequence
            self.minimum = minimum
            self.checksum = checksum
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

        func canMoveTo(_ next: ReferenceRangePolicyStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == ReferenceRangePolicyStatus.resolved
            case .resolved:
                return next == ReferenceRangePolicyStatus.reopened
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

        func moveTo(_ next: ReferenceRangePolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("reference range policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func adjustedLoad() -> Double {
            return ((minimum + Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> ReferenceRangePolicy {
            return ReferenceRangePolicy(
                code: code,
                label: label,
                patientRef: patientRef,
                sequence: sequence,
                minimum: minimum,
                checksum: checksum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a reference range policy in status open.
    static func newReferenceRangePolicy(_ code: String, label: String) -> ReferenceRangePolicy {
        return ReferenceRangePolicy(
            code: code,
            label: label,
            patientRef: "",
            sequence: 0,
            minimum: 0.0,
            checksum: "",
            status: ReferenceRangePolicyStatus.`open`
        )
    }
}
