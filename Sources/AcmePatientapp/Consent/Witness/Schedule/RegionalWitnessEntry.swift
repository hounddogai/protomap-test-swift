import AcmePlatform
import Foundation

extension Consent {
    /// Where a regional witness entry is in its life cycle.
    enum RegionalWitnessEntryStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One regional witness entry, with what the planners need to act on it.
    final class RegionalWitnessEntry {
        var code: String
        var label: String
        var maximum: Double
        var category: String
        var windowDays: Int
        var timezone: String
        var amount: Double
        var rate: Double
        var status: RegionalWitnessEntryStatus

        init(code: String, label: String, maximum: Double, category: String, windowDays: Int, timezone: String, amount: Double, rate: Double, status: RegionalWitnessEntryStatus) {
            self.code = code
            self.label = label
            self.maximum = maximum
            self.category = category
            self.windowDays = windowDays
            self.timezone = timezone
            self.amount = amount
            self.rate = rate
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RegionalWitnessEntryStatus) -> Bool {
            switch status {
            case .proposed:
                return next == RegionalWitnessEntryStatus.approved || next == RegionalWitnessEntryStatus.rejected
            case .approved:
                return next == RegionalWitnessEntryStatus.rejected
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: RegionalWitnessEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional witness entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("regional witness entry") \(code)"
        }

        func adjustedExposure() -> Double {
            return ((maximum - rate) * 100).rounded() / 100
        }

        func copyValue() -> RegionalWitnessEntry {
            return RegionalWitnessEntry(
                code: code,
                label: label,
                maximum: maximum,
                category: category,
                windowDays: windowDays,
                timezone: timezone,
                amount: amount,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a regional witness entry in status proposed.
    static func newRegionalWitnessEntry(_ code: String, label: String) -> RegionalWitnessEntry {
        return RegionalWitnessEntry(
            code: code,
            label: label,
            maximum: 0.0,
            category: "",
            windowDays: 0,
            timezone: "",
            amount: 0.0,
            rate: 0.0,
            status: RegionalWitnessEntryStatus.proposed
        )
    }
}
