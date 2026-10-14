import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a pending isolation tier is in its life cycle.
    enum PendingIsolationTierStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A pending isolation tier. Its code is unique within a tenant.
    final class PendingIsolationTier {
        var code: String
        var label: String
        var unit: String
        var channel: String
        var retries: Int
        var description: String
        var visitMinutes: Int
        var payer: String
        var amount: Double
        var threshold: Double
        var status: PendingIsolationTierStatus

        init(code: String, label: String, unit: String, channel: String, retries: Int, description: String, visitMinutes: Int, payer: String, amount: Double, threshold: Double, status: PendingIsolationTierStatus) {
            self.code = code
            self.label = label
            self.unit = unit
            self.channel = channel
            self.retries = retries
            self.description = description
            self.visitMinutes = visitMinutes
            self.payer = payer
            self.amount = amount
            self.threshold = threshold
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

        func canMoveTo(_ next: PendingIsolationTierStatus) -> Bool {
            switch status {
            case .planned:
                return next == PendingIsolationTierStatus.inProgress || next == PendingIsolationTierStatus.cancelled
            case .scheduled:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: PendingIsolationTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending isolation tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("pending isolation tier") \(code)"
        }

        func projectedTotal() -> Double {
            return ((Double(visitMinutes) - threshold) * 100).rounded() / 100
        }

        func copyValue() -> PendingIsolationTier {
            return PendingIsolationTier(
                code: code,
                label: label,
                unit: unit,
                channel: channel,
                retries: retries,
                description: description,
                visitMinutes: visitMinutes,
                payer: payer,
                amount: amount,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a pending isolation tier in status planned.
    static func newPendingIsolationTier(_ code: String, label: String) -> PendingIsolationTier {
        return PendingIsolationTier(
            code: code,
            label: label,
            unit: "",
            channel: "",
            retries: 0,
            description: "",
            visitMinutes: 0,
            payer: "",
            amount: 0.0,
            threshold: 0.0,
            status: PendingIsolationTierStatus.planned
        )
    }
}
