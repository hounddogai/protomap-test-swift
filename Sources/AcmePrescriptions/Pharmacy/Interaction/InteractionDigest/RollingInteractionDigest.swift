import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a rolling interaction digest is in its life cycle.
    enum RollingInteractionDigestStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A rolling interaction digest as the interaction team keeps it.
    final class RollingInteractionDigest {
        var code: String
        var title: String
        var externalRef: String
        var threshold: Double
        var durationMinutes: Int
        var batchSize: Int
        var reviewer: String
        var amount: Double
        var score: Double
        var notes: String
        var maximum: Double
        var status: RollingInteractionDigestStatus

        init(code: String, title: String, externalRef: String, threshold: Double, durationMinutes: Int, batchSize: Int, reviewer: String, amount: Double, score: Double, notes: String, maximum: Double, status: RollingInteractionDigestStatus) {
            self.code = code
            self.title = title
            self.externalRef = externalRef
            self.threshold = threshold
            self.durationMinutes = durationMinutes
            self.batchSize = batchSize
            self.reviewer = reviewer
            self.amount = amount
            self.score = score
            self.notes = notes
            self.maximum = maximum
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RollingInteractionDigestStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == RollingInteractionDigestStatus.rejected || next == RollingInteractionDigestStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: RollingInteractionDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling interaction digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("rolling interaction digest") \(code)"
        }

        func weightedExposure() -> Double {
            return (maximum * threshold * 100).rounded() / 100
        }

        func copyValue() -> RollingInteractionDigest {
            return RollingInteractionDigest(
                code: code,
                title: title,
                externalRef: externalRef,
                threshold: threshold,
                durationMinutes: durationMinutes,
                batchSize: batchSize,
                reviewer: reviewer,
                amount: amount,
                score: score,
                notes: notes,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a rolling interaction digest in status proposed.
    static func newRollingInteractionDigest(_ code: String, title: String) -> RollingInteractionDigest {
        return RollingInteractionDigest(
            code: code,
            title: title,
            externalRef: "",
            threshold: 0.0,
            durationMinutes: 0,
            batchSize: 0,
            reviewer: "",
            amount: 0.0,
            score: 0.0,
            notes: "",
            maximum: 0.0,
            status: RollingInteractionDigestStatus.proposed
        )
    }
}
