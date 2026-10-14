import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a dispense quota is in its life cycle.
    enum DispenseQuotaStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a dispense quota and its current status.
    final class DispenseQuota {
        var code: String
        var name: String
        var attempts: Int
        var ceiling: Double
        var minimum: Double
        var payer: String
        var graceDays: Int
        var retries: Int
        var summary: String
        var threshold: Double
        var channel: String
        var status: DispenseQuotaStatus

        init(code: String, name: String, attempts: Int, ceiling: Double, minimum: Double, payer: String, graceDays: Int, retries: Int, summary: String, threshold: Double, channel: String, status: DispenseQuotaStatus) {
            self.code = code
            self.name = name
            self.attempts = attempts
            self.ceiling = ceiling
            self.minimum = minimum
            self.payer = payer
            self.graceDays = graceDays
            self.retries = retries
            self.summary = summary
            self.threshold = threshold
            self.channel = channel
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

        func canMoveTo(_ next: DispenseQuotaStatus) -> Bool {
            switch status {
            case .new:
                return next == DispenseQuotaStatus.running
            case .queued:
                return next == DispenseQuotaStatus.running || next == DispenseQuotaStatus.done
            case .running:
                return next == DispenseQuotaStatus.done
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

        func moveTo(_ next: DispenseQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("dispense quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func effectiveTotal() -> Double {
            return ((Double(retries) + ceiling) * 100).rounded() / 100
        }

        func copyValue() -> DispenseQuota {
            return DispenseQuota(
                code: code,
                name: name,
                attempts: attempts,
                ceiling: ceiling,
                minimum: minimum,
                payer: payer,
                graceDays: graceDays,
                retries: retries,
                summary: summary,
                threshold: threshold,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a dispense quota in status new.
    static func newDispenseQuota(_ code: String, name: String) -> DispenseQuota {
        return DispenseQuota(
            code: code,
            name: name,
            attempts: 0,
            ceiling: 0.0,
            minimum: 0.0,
            payer: "",
            graceDays: 0,
            retries: 0,
            summary: "",
            threshold: 0.0,
            channel: "",
            status: DispenseQuotaStatus.new
        )
    }
}
