import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a transfer tier is in its life cycle.
    enum TransferTierStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A transfer tier. Its code is unique within a tenant.
    final class TransferTier {
        var code: String
        var label: String
        var score: Double
        var startsAt: Int
        var expiresAt: Int
        var priority: Int
        var batchSize: Int
        var specialty: String
        var status: TransferTierStatus

        init(code: String, label: String, score: Double, startsAt: Int, expiresAt: Int, priority: Int, batchSize: Int, specialty: String, status: TransferTierStatus) {
            self.code = code
            self.label = label
            self.score = score
            self.startsAt = startsAt
            self.expiresAt = expiresAt
            self.priority = priority
            self.batchSize = batchSize
            self.specialty = specialty
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

        func canMoveTo(_ next: TransferTierStatus) -> Bool {
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
                return next == TransferTierStatus.completed || next == TransferTierStatus.cancelled
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == TransferTierStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TransferTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("transfer tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func projectedLoad() -> Double {
            return (score * Double(startsAt) * 100).rounded() / 100
        }

        func copyValue() -> TransferTier {
            return TransferTier(
                code: code,
                label: label,
                score: score,
                startsAt: startsAt,
                expiresAt: expiresAt,
                priority: priority,
                batchSize: batchSize,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a transfer tier in status planned.
    static func newTransferTier(_ code: String, label: String) -> TransferTier {
        return TransferTier(
            code: code,
            label: label,
            score: 0.0,
            startsAt: 0,
            expiresAt: 0,
            priority: 0,
            batchSize: 0,
            specialty: "",
            status: TransferTierStatus.planned
        )
    }
}
