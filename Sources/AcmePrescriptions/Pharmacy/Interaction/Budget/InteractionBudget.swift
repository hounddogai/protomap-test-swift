import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a interaction budget is in its life cycle.
    enum InteractionBudgetStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A interaction budget as the interaction team keeps it.
    final class InteractionBudget {
        var code: String
        var title: String
        var checksum: String
        var visitMinutes: Int
        var maximum: Double
        var timezone: String
        var description: String
        var locale: String
        var status: InteractionBudgetStatus

        init(code: String, title: String, checksum: String, visitMinutes: Int, maximum: Double, timezone: String, description: String, locale: String, status: InteractionBudgetStatus) {
            self.code = code
            self.title = title
            self.checksum = checksum
            self.visitMinutes = visitMinutes
            self.maximum = maximum
            self.timezone = timezone
            self.description = description
            self.locale = locale
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

        func canMoveTo(_ next: InteractionBudgetStatus) -> Bool {
            switch status {
            case .idle:
                return next == InteractionBudgetStatus.warming
            case .warming:
                return next == InteractionBudgetStatus.ready
            case .ready:
                return next == InteractionBudgetStatus.stopped
            case .draining:
                return next == InteractionBudgetStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: InteractionBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("interaction budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func adjustedVolume() -> Double {
            return ((maximum + Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> InteractionBudget {
            return InteractionBudget(
                code: code,
                title: title,
                checksum: checksum,
                visitMinutes: visitMinutes,
                maximum: maximum,
                timezone: timezone,
                description: description,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a interaction budget in status idle.
    static func newInteractionBudget(_ code: String, title: String) -> InteractionBudget {
        return InteractionBudget(
            code: code,
            title: title,
            checksum: "",
            visitMinutes: 0,
            maximum: 0.0,
            timezone: "",
            description: "",
            locale: "",
            status: InteractionBudgetStatus.idle
        )
    }
}
