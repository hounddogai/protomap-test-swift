import AcmePlatform
import Foundation

extension Referrals {
    /// Where a tiered eligibility record is in its life cycle.
    enum TieredEligibilityRecordStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One tiered eligibility record, with what the planners need to act on it.
    final class TieredEligibilityRecord {
        var code: String
        var title: String
        var reviewer: String
        var windowDays: Int
        var active: Bool
        var batchSize: Int
        var status: TieredEligibilityRecordStatus

        init(code: String, title: String, reviewer: String, windowDays: Int, active: Bool, batchSize: Int, status: TieredEligibilityRecordStatus) {
            self.code = code
            self.title = title
            self.reviewer = reviewer
            self.windowDays = windowDays
            self.active = active
            self.batchSize = batchSize
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TieredEligibilityRecordStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .ready:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == TieredEligibilityRecordStatus.stopped
            case .ready:
                return next == TieredEligibilityRecordStatus.stopped
            case .draining:
                return next == TieredEligibilityRecordStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredEligibilityRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered eligibility record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("tiered eligibility record") \(code)"
        }

        func projectedTotal() -> Double {
            return ((Double(batchSize) + Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> TieredEligibilityRecord {
            return TieredEligibilityRecord(
                code: code,
                title: title,
                reviewer: reviewer,
                windowDays: windowDays,
                active: active,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a tiered eligibility record in status idle.
    static func newTieredEligibilityRecord(_ code: String, title: String) -> TieredEligibilityRecord {
        return TieredEligibilityRecord(
            code: code,
            title: title,
            reviewer: "",
            windowDays: 0,
            active: false,
            batchSize: 0,
            status: TieredEligibilityRecordStatus.idle
        )
    }
}
