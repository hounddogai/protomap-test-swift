import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a pending inventory notice is in its life cycle.
    enum PendingInventoryNoticeStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A pending inventory notice as the inventory team keeps it.
    final class PendingInventoryNotice {
        var code: String
        var title: String
        var currency: String
        var visitMinutes: Int
        var reviewer: String
        var diagnosisCode: String
        var locale: String
        var status: PendingInventoryNoticeStatus

        init(code: String, title: String, currency: String, visitMinutes: Int, reviewer: String, diagnosisCode: String, locale: String, status: PendingInventoryNoticeStatus) {
            self.code = code
            self.title = title
            self.currency = currency
            self.visitMinutes = visitMinutes
            self.reviewer = reviewer
            self.diagnosisCode = diagnosisCode
            self.locale = locale
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

        func canMoveTo(_ next: PendingInventoryNoticeStatus) -> Bool {
            switch status {
            case .new:
                return next == PendingInventoryNoticeStatus.queued || next == PendingInventoryNoticeStatus.failed
            case .queued:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == PendingInventoryNoticeStatus.done || next == PendingInventoryNoticeStatus.failed
            case .done:
                return next == PendingInventoryNoticeStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingInventoryNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending inventory notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func measuredValue() -> Double {
            return Double(visitMinutes)
        }

        func copyValue() -> PendingInventoryNotice {
            return PendingInventoryNotice(
                code: code,
                title: title,
                currency: currency,
                visitMinutes: visitMinutes,
                reviewer: reviewer,
                diagnosisCode: diagnosisCode,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a pending inventory notice in status new.
    static func newPendingInventoryNotice(_ code: String, title: String) -> PendingInventoryNotice {
        return PendingInventoryNotice(
            code: code,
            title: title,
            currency: "",
            visitMinutes: 0,
            reviewer: "",
            diagnosisCode: "",
            locale: "",
            status: PendingInventoryNoticeStatus.new
        )
    }
}
