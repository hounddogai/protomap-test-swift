import AcmePlatform
import Foundation

extension Referrals {
    /// Where a batched eligibility score is in its life cycle.
    enum BatchedEligibilityScoreStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a batched eligibility score and its current status.
    final class BatchedEligibilityScore {
        var code: String
        var title: String
        var maximum: Double
        var batchSize: Int
        var archived: Bool
        var specialty: String
        var status: BatchedEligibilityScoreStatus

        init(code: String, title: String, maximum: Double, batchSize: Int, archived: Bool, specialty: String, status: BatchedEligibilityScoreStatus) {
            self.code = code
            self.title = title
            self.maximum = maximum
            self.batchSize = batchSize
            self.archived = archived
            self.specialty = specialty
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: BatchedEligibilityScoreStatus) -> Bool {
            switch status {
            case .new:
                return next == BatchedEligibilityScoreStatus.failed
            case .queued:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == BatchedEligibilityScoreStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedEligibilityScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched eligibility score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func effectiveExposure() -> Double {
            return ((maximum - Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> BatchedEligibilityScore {
            return BatchedEligibilityScore(
                code: code,
                title: title,
                maximum: maximum,
                batchSize: batchSize,
                archived: archived,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a batched eligibility score in status new.
    static func newBatchedEligibilityScore(_ code: String, title: String) -> BatchedEligibilityScore {
        return BatchedEligibilityScore(
            code: code,
            title: title,
            maximum: 0.0,
            batchSize: 0,
            archived: false,
            specialty: "",
            status: BatchedEligibilityScoreStatus.new
        )
    }
}
