import AcmePlatform
import Foundation

extension Referrals {
    /// Where a lenient slot digest is in its life cycle.
    enum LenientSlotDigestStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One lenient slot digest, with what the planners need to act on it.
    final class LenientSlotDigest {
        var code: String
        var title: String
        var summary: String
        var graceDays: Int
        var batchSize: Int
        var durationMinutes: Int
        var locale: String
        var label: String
        var attempts: Int
        var amount: Double
        var windowDays: Int
        var status: LenientSlotDigestStatus

        init(code: String, title: String, summary: String, graceDays: Int, batchSize: Int, durationMinutes: Int, locale: String, label: String, attempts: Int, amount: Double, windowDays: Int, status: LenientSlotDigestStatus) {
            self.code = code
            self.title = title
            self.summary = summary
            self.graceDays = graceDays
            self.batchSize = batchSize
            self.durationMinutes = durationMinutes
            self.locale = locale
            self.label = label
            self.attempts = attempts
            self.amount = amount
            self.windowDays = windowDays
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LenientSlotDigestStatus) -> Bool {
            switch status {
            case .created:
                return next == LenientSlotDigestStatus.validated
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == LenientSlotDigestStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientSlotDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient slot digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(title))"
        }

        func projectedLoad() -> Double {
            return ((Double(graceDays) + Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> LenientSlotDigest {
            return LenientSlotDigest(
                code: code,
                title: title,
                summary: summary,
                graceDays: graceDays,
                batchSize: batchSize,
                durationMinutes: durationMinutes,
                locale: locale,
                label: label,
                attempts: attempts,
                amount: amount,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a lenient slot digest in status created.
    static func newLenientSlotDigest(_ code: String, title: String) -> LenientSlotDigest {
        return LenientSlotDigest(
            code: code,
            title: title,
            summary: "",
            graceDays: 0,
            batchSize: 0,
            durationMinutes: 0,
            locale: "",
            label: "",
            attempts: 0,
            amount: 0.0,
            windowDays: 0,
            status: LenientSlotDigestStatus.created
        )
    }
}
