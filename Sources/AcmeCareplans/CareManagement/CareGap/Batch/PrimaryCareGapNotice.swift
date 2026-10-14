import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a primary care gap notice is in its life cycle.
    enum PrimaryCareGapNoticeStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A primary care gap notice. Its code is unique within a tenant.
    final class PrimaryCareGapNotice {
        var code: String
        var name: String
        var quantity: Int
        var timezone: String
        var endsAt: Int
        var status: PrimaryCareGapNoticeStatus

        init(code: String, name: String, quantity: Int, timezone: String, endsAt: Int, status: PrimaryCareGapNoticeStatus) {
            self.code = code
            self.name = name
            self.quantity = quantity
            self.timezone = timezone
            self.endsAt = endsAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PrimaryCareGapNoticeStatus) -> Bool {
            switch status {
            case .draft:
                return next == PrimaryCareGapNoticeStatus.active
            case .pending:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == PrimaryCareGapNoticeStatus.closed
            case .suspended:
                return next == PrimaryCareGapNoticeStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryCareGapNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary care gap notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("primary care gap notice") \(code)"
        }

        func weightedVolume() -> Double {
            return ((Double(quantity) + Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryCareGapNotice {
            return PrimaryCareGapNotice(
                code: code,
                name: name,
                quantity: quantity,
                timezone: timezone,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a primary care gap notice in status draft.
    static func newPrimaryCareGapNotice(_ code: String, name: String) -> PrimaryCareGapNotice {
        return PrimaryCareGapNotice(
            code: code,
            name: name,
            quantity: 0,
            timezone: "",
            endsAt: 0,
            status: PrimaryCareGapNoticeStatus.draft
        )
    }
}
