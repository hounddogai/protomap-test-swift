import AcmePlatform
import Foundation

extension Referrals {
    /// Where a seasonal closure entry is in its life cycle.
    enum SeasonalClosureEntryStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A seasonal closure entry as the closure team keeps it.
    final class SeasonalClosureEntry {
        var code: String
        var title: String
        var timezone: String
        var locale: String
        var reviewer: String
        var cost: Double
        var notes: String
        var quantity: Int
        var summary: String
        var region: String
        var dosageMg: Double
        var status: SeasonalClosureEntryStatus

        init(code: String, title: String, timezone: String, locale: String, reviewer: String, cost: Double, notes: String, quantity: Int, summary: String, region: String, dosageMg: Double, status: SeasonalClosureEntryStatus) {
            self.code = code
            self.title = title
            self.timezone = timezone
            self.locale = locale
            self.reviewer = reviewer
            self.cost = cost
            self.notes = notes
            self.quantity = quantity
            self.summary = summary
            self.region = region
            self.dosageMg = dosageMg
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

        func canMoveTo(_ next: SeasonalClosureEntryStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == SeasonalClosureEntryStatus.ready || next == SeasonalClosureEntryStatus.draining
            case .ready:
                return next == SeasonalClosureEntryStatus.draining || next == SeasonalClosureEntryStatus.stopped
            case .draining:
                return next == SeasonalClosureEntryStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalClosureEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal closure entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("seasonal closure entry") \(code)"
        }

        func weightedValue() -> Double {
            return ((cost + Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalClosureEntry {
            return SeasonalClosureEntry(
                code: code,
                title: title,
                timezone: timezone,
                locale: locale,
                reviewer: reviewer,
                cost: cost,
                notes: notes,
                quantity: quantity,
                summary: summary,
                region: region,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a seasonal closure entry in status idle.
    static func newSeasonalClosureEntry(_ code: String, title: String) -> SeasonalClosureEntry {
        return SeasonalClosureEntry(
            code: code,
            title: title,
            timezone: "",
            locale: "",
            reviewer: "",
            cost: 0.0,
            notes: "",
            quantity: 0,
            summary: "",
            region: "",
            dosageMg: 0.0,
            status: SeasonalClosureEntryStatus.idle
        )
    }
}
