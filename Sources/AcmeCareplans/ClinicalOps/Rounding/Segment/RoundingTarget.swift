import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a rounding target is in its life cycle.
    enum RoundingTargetStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A rounding target as the rounding team keeps it.
    final class RoundingTarget {
        var code: String
        var label: String
        var pinned: Bool
        var description: String
        var procedureCode: String
        var margin: Double
        var version: Int
        var retries: Int
        var dosageMg: Double
        var sequence: Int
        var diagnosisCode: String
        var status: RoundingTargetStatus

        init(code: String, label: String, pinned: Bool, description: String, procedureCode: String, margin: Double, version: Int, retries: Int, dosageMg: Double, sequence: Int, diagnosisCode: String, status: RoundingTargetStatus) {
            self.code = code
            self.label = label
            self.pinned = pinned
            self.description = description
            self.procedureCode = procedureCode
            self.margin = margin
            self.version = version
            self.retries = retries
            self.dosageMg = dosageMg
            self.sequence = sequence
            self.diagnosisCode = diagnosisCode
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

        func canMoveTo(_ next: RoundingTargetStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .resolved:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == RoundingTargetStatus.archived
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

        func moveTo(_ next: RoundingTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rounding target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\("rounding target") \(code)"
        }

        func projectedVolume() -> Double {
            return ((Double(sequence) - Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> RoundingTarget {
            return RoundingTarget(
                code: code,
                label: label,
                pinned: pinned,
                description: description,
                procedureCode: procedureCode,
                margin: margin,
                version: version,
                retries: retries,
                dosageMg: dosageMg,
                sequence: sequence,
                diagnosisCode: diagnosisCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a rounding target in status open.
    static func newRoundingTarget(_ code: String, label: String) -> RoundingTarget {
        return RoundingTarget(
            code: code,
            label: label,
            pinned: false,
            description: "",
            procedureCode: "",
            margin: 0.0,
            version: 0,
            retries: 0,
            dosageMg: 0.0,
            sequence: 0,
            diagnosisCode: "",
            status: RoundingTargetStatus.`open`
        )
    }
}
