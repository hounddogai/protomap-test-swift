import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a scheduled task review is in its life cycle.
    enum ScheduledTaskReviewStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A scheduled task review. Its code is unique within a tenant.
    final class ScheduledTaskReview {
        var code: String
        var label: String
        var description: String
        var copay: Double
        var minimum: Double
        var sequence: Int
        var threshold: Double
        var maximum: Double
        var version: Int
        var payer: String
        var expiresAt: Int
        var status: ScheduledTaskReviewStatus

        init(code: String, label: String, description: String, copay: Double, minimum: Double, sequence: Int, threshold: Double, maximum: Double, version: Int, payer: String, expiresAt: Int, status: ScheduledTaskReviewStatus) {
            self.code = code
            self.label = label
            self.description = description
            self.copay = copay
            self.minimum = minimum
            self.sequence = sequence
            self.threshold = threshold
            self.maximum = maximum
            self.version = version
            self.payer = payer
            self.expiresAt = expiresAt
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

        func canMoveTo(_ next: ScheduledTaskReviewStatus) -> Bool {
            switch status {
            case .new:
                return next == ScheduledTaskReviewStatus.done
            case .queued:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: ScheduledTaskReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled task review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func weightedLoad() -> Double {
            return ((copay + maximum) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledTaskReview {
            return ScheduledTaskReview(
                code: code,
                label: label,
                description: description,
                copay: copay,
                minimum: minimum,
                sequence: sequence,
                threshold: threshold,
                maximum: maximum,
                version: version,
                payer: payer,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a scheduled task review in status new.
    static func newScheduledTaskReview(_ code: String, label: String) -> ScheduledTaskReview {
        return ScheduledTaskReview(
            code: code,
            label: label,
            description: "",
            copay: 0.0,
            minimum: 0.0,
            sequence: 0,
            threshold: 0.0,
            maximum: 0.0,
            version: 0,
            payer: "",
            expiresAt: 0,
            status: ScheduledTaskReviewStatus.new
        )
    }
}
