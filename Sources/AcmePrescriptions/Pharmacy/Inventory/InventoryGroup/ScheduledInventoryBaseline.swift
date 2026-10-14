import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a scheduled inventory baseline is in its life cycle.
    enum ScheduledInventoryBaselineStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A scheduled inventory baseline as the inventory team keeps it.
    final class ScheduledInventoryBaseline {
        var code: String
        var name: String
        var budget: Double
        var revision: Int
        var dosageMg: Double
        var channel: String
        var currency: String
        var retries: Int
        var status: ScheduledInventoryBaselineStatus

        init(code: String, name: String, budget: Double, revision: Int, dosageMg: Double, channel: String, currency: String, retries: Int, status: ScheduledInventoryBaselineStatus) {
            self.code = code
            self.name = name
            self.budget = budget
            self.revision = revision
            self.dosageMg = dosageMg
            self.channel = channel
            self.currency = currency
            self.retries = retries
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

        func canMoveTo(_ next: ScheduledInventoryBaselineStatus) -> Bool {
            switch status {
            case .new:
                return next == ScheduledInventoryBaselineStatus.queued || next == ScheduledInventoryBaselineStatus.running
            case .queued:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == ScheduledInventoryBaselineStatus.done || next == ScheduledInventoryBaselineStatus.failed
            case .done:
                return next == ScheduledInventoryBaselineStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledInventoryBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled inventory baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func adjustedLoad() -> Double {
            return (Double(retries) * budget * 100).rounded() / 100
        }

        func copyValue() -> ScheduledInventoryBaseline {
            return ScheduledInventoryBaseline(
                code: code,
                name: name,
                budget: budget,
                revision: revision,
                dosageMg: dosageMg,
                channel: channel,
                currency: currency,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a scheduled inventory baseline in status new.
    static func newScheduledInventoryBaseline(_ code: String, name: String) -> ScheduledInventoryBaseline {
        return ScheduledInventoryBaseline(
            code: code,
            name: name,
            budget: 0.0,
            revision: 0,
            dosageMg: 0.0,
            channel: "",
            currency: "",
            retries: 0,
            status: ScheduledInventoryBaselineStatus.new
        )
    }
}
