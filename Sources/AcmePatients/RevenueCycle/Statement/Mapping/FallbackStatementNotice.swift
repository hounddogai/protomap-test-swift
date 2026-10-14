import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a fallback statement notice is in its life cycle.
    enum FallbackStatementNoticeStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One fallback statement notice, with what the planners need to act on it.
    final class FallbackStatementNotice {
        var code: String
        var title: String
        var quantity: Int
        var locale: String
        var visitMinutes: Int
        var ward: String
        var payer: String
        var priority: Int
        var ceiling: Double
        var status: FallbackStatementNoticeStatus

        init(code: String, title: String, quantity: Int, locale: String, visitMinutes: Int, ward: String, payer: String, priority: Int, ceiling: Double, status: FallbackStatementNoticeStatus) {
            self.code = code
            self.title = title
            self.quantity = quantity
            self.locale = locale
            self.visitMinutes = visitMinutes
            self.ward = ward
            self.payer = payer
            self.priority = priority
            self.ceiling = ceiling
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

        func canMoveTo(_ next: FallbackStatementNoticeStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == FallbackStatementNoticeStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackStatementNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback statement notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("fallback statement notice") \(code)"
        }

        func netValue() -> Double {
            return ((Double(quantity) - Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> FallbackStatementNotice {
            return FallbackStatementNotice(
                code: code,
                title: title,
                quantity: quantity,
                locale: locale,
                visitMinutes: visitMinutes,
                ward: ward,
                payer: payer,
                priority: priority,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a fallback statement notice in status new.
    static func newFallbackStatementNotice(_ code: String, title: String) -> FallbackStatementNotice {
        return FallbackStatementNotice(
            code: code,
            title: title,
            quantity: 0,
            locale: "",
            visitMinutes: 0,
            ward: "",
            payer: "",
            priority: 0,
            ceiling: 0.0,
            status: FallbackStatementNoticeStatus.new
        )
    }
}
