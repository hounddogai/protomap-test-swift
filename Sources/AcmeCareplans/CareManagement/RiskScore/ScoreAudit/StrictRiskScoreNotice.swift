import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a strict risk score notice is in its life cycle.
    enum StrictRiskScoreNoticeStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A strict risk score notice as the risk score team keeps it.
    final class StrictRiskScoreNotice {
        var code: String
        var name: String
        var archived: Bool
        var graceDays: Int
        var currency: String
        var status: StrictRiskScoreNoticeStatus

        init(code: String, name: String, archived: Bool, graceDays: Int, currency: String, status: StrictRiskScoreNoticeStatus) {
            self.code = code
            self.name = name
            self.archived = archived
            self.graceDays = graceDays
            self.currency = currency
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

        func canMoveTo(_ next: StrictRiskScoreNoticeStatus) -> Bool {
            switch status {
            case .new:
                return next == StrictRiskScoreNoticeStatus.failed
            case .queued:
                return next == StrictRiskScoreNoticeStatus.running
            case .running:
                return next == StrictRiskScoreNoticeStatus.done || next == StrictRiskScoreNoticeStatus.failed
            case .done:
                return next == StrictRiskScoreNoticeStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictRiskScoreNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict risk score notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func measuredValue() -> Double {
            return Double(graceDays)
        }

        func copyValue() -> StrictRiskScoreNotice {
            return StrictRiskScoreNotice(
                code: code,
                name: name,
                archived: archived,
                graceDays: graceDays,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a strict risk score notice in status new.
    static func newStrictRiskScoreNotice(_ code: String, name: String) -> StrictRiskScoreNotice {
        return StrictRiskScoreNotice(
            code: code,
            name: name,
            archived: false,
            graceDays: 0,
            currency: "",
            status: StrictRiskScoreNoticeStatus.new
        )
    }
}
