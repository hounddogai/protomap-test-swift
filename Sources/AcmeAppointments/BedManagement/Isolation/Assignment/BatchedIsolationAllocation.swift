import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a batched isolation allocation is in its life cycle.
    enum BatchedIsolationAllocationStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a batched isolation allocation and its current status.
    final class BatchedIsolationAllocation {
        var code: String
        var label: String
        var score: Double
        var title: String
        var attempts: Int
        var diagnosisCode: String
        var timezone: String
        var segment: String
        var minimum: Double
        var expiresAt: Int
        var status: BatchedIsolationAllocationStatus

        init(code: String, label: String, score: Double, title: String, attempts: Int, diagnosisCode: String, timezone: String, segment: String, minimum: Double, expiresAt: Int, status: BatchedIsolationAllocationStatus) {
            self.code = code
            self.label = label
            self.score = score
            self.title = title
            self.attempts = attempts
            self.diagnosisCode = diagnosisCode
            self.timezone = timezone
            self.segment = segment
            self.minimum = minimum
            self.expiresAt = expiresAt
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

        func canMoveTo(_ next: BatchedIsolationAllocationStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened, .archived:
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
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == BatchedIsolationAllocationStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedIsolationAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched isolation allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func projectedExposure() -> Double {
            return ((Double(attempts) + minimum) * 100).rounded() / 100
        }

        func copyValue() -> BatchedIsolationAllocation {
            return BatchedIsolationAllocation(
                code: code,
                label: label,
                score: score,
                title: title,
                attempts: attempts,
                diagnosisCode: diagnosisCode,
                timezone: timezone,
                segment: segment,
                minimum: minimum,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a batched isolation allocation in status open.
    static func newBatchedIsolationAllocation(_ code: String, label: String) -> BatchedIsolationAllocation {
        return BatchedIsolationAllocation(
            code: code,
            label: label,
            score: 0.0,
            title: "",
            attempts: 0,
            diagnosisCode: "",
            timezone: "",
            segment: "",
            minimum: 0.0,
            expiresAt: 0,
            status: BatchedIsolationAllocationStatus.`open`
        )
    }
}
