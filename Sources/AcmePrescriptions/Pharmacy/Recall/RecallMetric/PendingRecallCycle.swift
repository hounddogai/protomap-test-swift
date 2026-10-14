import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a pending recall cycle is in its life cycle.
    enum PendingRecallCycleStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A pending recall cycle as the recall team keeps it.
    final class PendingRecallCycle {
        var code: String
        var title: String
        var currency: String
        var minimum: Double
        var graceDays: Int
        var segment: String
        var phone: String
        var reviewer: String
        var durationMinutes: Int
        var status: PendingRecallCycleStatus

        init(code: String, title: String, currency: String, minimum: Double, graceDays: Int, segment: String, phone: String, reviewer: String, durationMinutes: Int, status: PendingRecallCycleStatus) {
            self.code = code
            self.title = title
            self.currency = currency
            self.minimum = minimum
            self.graceDays = graceDays
            self.segment = segment
            self.phone = phone
            self.reviewer = reviewer
            self.durationMinutes = durationMinutes
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

        func canMoveTo(_ next: PendingRecallCycleStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == PendingRecallCycleStatus.failed
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

        func moveTo(_ next: PendingRecallCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending recall cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("pending recall cycle") \(code)"
        }

        func weightedTotal() -> Double {
            return ((Double(durationMinutes) + minimum) * 100).rounded() / 100
        }

        func copyValue() -> PendingRecallCycle {
            return PendingRecallCycle(
                code: code,
                title: title,
                currency: currency,
                minimum: minimum,
                graceDays: graceDays,
                segment: segment,
                phone: phone,
                reviewer: reviewer,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a pending recall cycle in status new.
    static func newPendingRecallCycle(_ code: String, title: String) -> PendingRecallCycle {
        return PendingRecallCycle(
            code: code,
            title: title,
            currency: "",
            minimum: 0.0,
            graceDays: 0,
            segment: "",
            phone: "",
            reviewer: "",
            durationMinutes: 0,
            status: PendingRecallCycleStatus.new
        )
    }
}
