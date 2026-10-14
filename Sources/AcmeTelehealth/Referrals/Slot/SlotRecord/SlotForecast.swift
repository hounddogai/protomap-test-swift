import AcmePlatform
import Foundation

extension Referrals {
    /// Where a slot forecast is in its life cycle.
    enum SlotForecastStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One slot forecast, with what the planners need to act on it.
    final class SlotForecast {
        var code: String
        var name: String
        var maximum: Double
        var specialty: String
        var contactEmail: String
        var cost: Double
        var windowDays: Int
        var title: String
        var ratio: Double
        var priority: Int
        var status: SlotForecastStatus

        init(code: String, name: String, maximum: Double, specialty: String, contactEmail: String, cost: Double, windowDays: Int, title: String, ratio: Double, priority: Int, status: SlotForecastStatus) {
            self.code = code
            self.name = name
            self.maximum = maximum
            self.specialty = specialty
            self.contactEmail = contactEmail
            self.cost = cost
            self.windowDays = windowDays
            self.title = title
            self.ratio = ratio
            self.priority = priority
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SlotForecastStatus) -> Bool {
            switch status {
            case .`open`:
                return next == SlotForecastStatus.reopened || next == SlotForecastStatus.archived
            case .inReview:
                return next == SlotForecastStatus.resolved || next == SlotForecastStatus.reopened
            case .resolved:
                return next == SlotForecastStatus.reopened
            case .reopened:
                return next == SlotForecastStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SlotForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("slot forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("slot forecast") \(code)"
        }

        func effectiveValue() -> Double {
            return ((maximum - ratio) * 100).rounded() / 100
        }

        func copyValue() -> SlotForecast {
            return SlotForecast(
                code: code,
                name: name,
                maximum: maximum,
                specialty: specialty,
                contactEmail: contactEmail,
                cost: cost,
                windowDays: windowDays,
                title: title,
                ratio: ratio,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a slot forecast in status open.
    static func newSlotForecast(_ code: String, name: String) -> SlotForecast {
        return SlotForecast(
            code: code,
            name: name,
            maximum: 0.0,
            specialty: "",
            contactEmail: "",
            cost: 0.0,
            windowDays: 0,
            title: "",
            ratio: 0.0,
            priority: 0,
            status: SlotForecastStatus.`open`
        )
    }
}
