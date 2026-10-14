import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a batched goal draft is in its life cycle.
    enum BatchedGoalDraftStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A batched goal draft. Its code is unique within a tenant.
    final class BatchedGoalDraft {
        var code: String
        var name: String
        var region: String
        var minimum: Double
        var acuity: Int
        var status: BatchedGoalDraftStatus

        init(code: String, name: String, region: String, minimum: Double, acuity: Int, status: BatchedGoalDraftStatus) {
            self.code = code
            self.name = name
            self.region = region
            self.minimum = minimum
            self.acuity = acuity
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

        func canMoveTo(_ next: BatchedGoalDraftStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == BatchedGoalDraftStatus.reopened || next == BatchedGoalDraftStatus.archived
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

        func moveTo(_ next: BatchedGoalDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched goal draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("batched goal draft") \(code)"
        }

        func weightedExposure() -> Double {
            return (Double(acuity) * minimum * 100).rounded() / 100
        }

        func copyValue() -> BatchedGoalDraft {
            return BatchedGoalDraft(
                code: code,
                name: name,
                region: region,
                minimum: minimum,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a batched goal draft in status open.
    static func newBatchedGoalDraft(_ code: String, name: String) -> BatchedGoalDraft {
        return BatchedGoalDraft(
            code: code,
            name: name,
            region: "",
            minimum: 0.0,
            acuity: 0,
            status: BatchedGoalDraftStatus.`open`
        )
    }
}
