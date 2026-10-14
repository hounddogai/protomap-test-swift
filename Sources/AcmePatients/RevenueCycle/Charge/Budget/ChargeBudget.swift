import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a charge budget is in its life cycle.
    enum ChargeBudgetStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a charge budget and its current status.
    final class ChargeBudget {
        var code: String
        var name: String
        var priority: Int
        var pinned: Bool
        var contactEmail: String
        var dosageMg: Double
        var locale: String
        var visible: Bool
        var archived: Bool
        var graceDays: Int
        var channel: String
        var status: ChargeBudgetStatus

        init(code: String, name: String, priority: Int, pinned: Bool, contactEmail: String, dosageMg: Double, locale: String, visible: Bool, archived: Bool, graceDays: Int, channel: String, status: ChargeBudgetStatus) {
            self.code = code
            self.name = name
            self.priority = priority
            self.pinned = pinned
            self.contactEmail = contactEmail
            self.dosageMg = dosageMg
            self.locale = locale
            self.visible = visible
            self.archived = archived
            self.graceDays = graceDays
            self.channel = channel
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

        func canMoveTo(_ next: ChargeBudgetStatus) -> Bool {
            switch status {
            case .draft:
                return next == ChargeBudgetStatus.suspended || next == ChargeBudgetStatus.closed
            case .pending:
                return next == ChargeBudgetStatus.closed
            case .active:
                return next == ChargeBudgetStatus.suspended || next == ChargeBudgetStatus.closed
            case .suspended:
                return next == ChargeBudgetStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ChargeBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("charge budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func projectedExposure() -> Double {
            return ((Double(graceDays) - dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> ChargeBudget {
            return ChargeBudget(
                code: code,
                name: name,
                priority: priority,
                pinned: pinned,
                contactEmail: contactEmail,
                dosageMg: dosageMg,
                locale: locale,
                visible: visible,
                archived: archived,
                graceDays: graceDays,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a charge budget in status draft.
    static func newChargeBudget(_ code: String, name: String) -> ChargeBudget {
        return ChargeBudget(
            code: code,
            name: name,
            priority: 0,
            pinned: false,
            contactEmail: "",
            dosageMg: 0.0,
            locale: "",
            visible: false,
            archived: false,
            graceDays: 0,
            channel: "",
            status: ChargeBudgetStatus.draft
        )
    }
}
