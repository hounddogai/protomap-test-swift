import AcmePlatform
import Foundation

extension Staffing {
    /// Where a regional float pool summary is in its life cycle.
    enum RegionalFloatPoolSummaryStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A regional float pool summary as the float pool team keeps it.
    final class RegionalFloatPoolSummary {
        var code: String
        var title: String
        var maximum: Double
        var ceiling: Double
        var score: Double
        var specialty: String
        var amount: Double
        var ward: String
        var discount: Double
        var status: RegionalFloatPoolSummaryStatus

        init(code: String, title: String, maximum: Double, ceiling: Double, score: Double, specialty: String, amount: Double, ward: String, discount: Double, status: RegionalFloatPoolSummaryStatus) {
            self.code = code
            self.title = title
            self.maximum = maximum
            self.ceiling = ceiling
            self.score = score
            self.specialty = specialty
            self.amount = amount
            self.ward = ward
            self.discount = discount
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

        func canMoveTo(_ next: RegionalFloatPoolSummaryStatus) -> Bool {
            switch status {
            case .draft:
                return next == RegionalFloatPoolSummaryStatus.active || next == RegionalFloatPoolSummaryStatus.suspended
            case .pending:
                return next == RegionalFloatPoolSummaryStatus.active
            case .active:
                return next == RegionalFloatPoolSummaryStatus.suspended || next == RegionalFloatPoolSummaryStatus.closed
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: RegionalFloatPoolSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional float pool summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func weightedVolume() -> Double {
            return ((maximum - score) * 100).rounded() / 100
        }

        func copyValue() -> RegionalFloatPoolSummary {
            return RegionalFloatPoolSummary(
                code: code,
                title: title,
                maximum: maximum,
                ceiling: ceiling,
                score: score,
                specialty: specialty,
                amount: amount,
                ward: ward,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a regional float pool summary in status draft.
    static func newRegionalFloatPoolSummary(_ code: String, title: String) -> RegionalFloatPoolSummary {
        return RegionalFloatPoolSummary(
            code: code,
            title: title,
            maximum: 0.0,
            ceiling: 0.0,
            score: 0.0,
            specialty: "",
            amount: 0.0,
            ward: "",
            discount: 0.0,
            status: RegionalFloatPoolSummaryStatus.draft
        )
    }
}
