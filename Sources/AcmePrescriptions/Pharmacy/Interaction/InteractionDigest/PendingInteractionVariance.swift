import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a pending interaction variance is in its life cycle.
    enum PendingInteractionVarianceStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a pending interaction variance and its current status.
    final class PendingInteractionVariance {
        var code: String
        var label: String
        var expiresAt: Int
        var limit: Int
        var checksum: String
        var title: String
        var acuity: Int
        var batchSize: Int
        var status: PendingInteractionVarianceStatus

        init(code: String, label: String, expiresAt: Int, limit: Int, checksum: String, title: String, acuity: Int, batchSize: Int, status: PendingInteractionVarianceStatus) {
            self.code = code
            self.label = label
            self.expiresAt = expiresAt
            self.limit = limit
            self.checksum = checksum
            self.title = title
            self.acuity = acuity
            self.batchSize = batchSize
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PendingInteractionVarianceStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == PendingInteractionVarianceStatus.completed
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: PendingInteractionVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending interaction variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("pending interaction variance") \(code)"
        }

        func weightedExposure() -> Double {
            return ((Double(acuity) - Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> PendingInteractionVariance {
            return PendingInteractionVariance(
                code: code,
                label: label,
                expiresAt: expiresAt,
                limit: limit,
                checksum: checksum,
                title: title,
                acuity: acuity,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a pending interaction variance in status planned.
    static func newPendingInteractionVariance(_ code: String, label: String) -> PendingInteractionVariance {
        return PendingInteractionVariance(
            code: code,
            label: label,
            expiresAt: 0,
            limit: 0,
            checksum: "",
            title: "",
            acuity: 0,
            batchSize: 0,
            status: PendingInteractionVarianceStatus.planned
        )
    }
}
