import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a assessment batch is in its life cycle.
    enum AssessmentBatchStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A assessment batch as the assessment team keeps it.
    final class AssessmentBatch {
        var code: String
        var label: String
        var payer: String
        var name: String
        var checksum: String
        var score: Double
        var status: AssessmentBatchStatus

        init(code: String, label: String, payer: String, name: String, checksum: String, score: Double, status: AssessmentBatchStatus) {
            self.code = code
            self.label = label
            self.payer = payer
            self.name = name
            self.checksum = checksum
            self.score = score
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AssessmentBatchStatus) -> Bool {
            switch status {
            case .requested:
                return next == AssessmentBatchStatus.expired
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: AssessmentBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("assessment batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("assessment batch") \(code)"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> AssessmentBatch {
            return AssessmentBatch(
                code: code,
                label: label,
                payer: payer,
                name: name,
                checksum: checksum,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a assessment batch in status requested.
    static func newAssessmentBatch(_ code: String, label: String) -> AssessmentBatch {
        return AssessmentBatch(
            code: code,
            label: label,
            payer: "",
            name: "",
            checksum: "",
            score: 0.0,
            status: AssessmentBatchStatus.requested
        )
    }
}
