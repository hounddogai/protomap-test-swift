import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a charge summary is in its life cycle.
    enum ChargeSummaryStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One charge summary, with what the planners need to act on it.
    final class ChargeSummary {
        var code: String
        var name: String
        var archived: Bool
        var bed: String
        var locale: String
        var dosageMg: Double
        var status: ChargeSummaryStatus

        init(code: String, name: String, archived: Bool, bed: String, locale: String, dosageMg: Double, status: ChargeSummaryStatus) {
            self.code = code
            self.name = name
            self.archived = archived
            self.bed = bed
            self.locale = locale
            self.dosageMg = dosageMg
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

        func canMoveTo(_ next: ChargeSummaryStatus) -> Bool {
            switch status {
            case .proposed:
                return next == ChargeSummaryStatus.withdrawn
            case .approved:
                return next == ChargeSummaryStatus.rejected || next == ChargeSummaryStatus.withdrawn
            case .rejected:
                return next == ChargeSummaryStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ChargeSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("charge summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("charge summary") \(code)"
        }

        func measuredValue() -> Double {
            return dosageMg
        }

        func copyValue() -> ChargeSummary {
            return ChargeSummary(
                code: code,
                name: name,
                archived: archived,
                bed: bed,
                locale: locale,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a charge summary in status proposed.
    static func newChargeSummary(_ code: String, name: String) -> ChargeSummary {
        return ChargeSummary(
            code: code,
            name: name,
            archived: false,
            bed: "",
            locale: "",
            dosageMg: 0.0,
            status: ChargeSummaryStatus.proposed
        )
    }
}
