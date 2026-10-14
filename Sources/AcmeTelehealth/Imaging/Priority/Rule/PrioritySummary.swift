import AcmePlatform
import Foundation

extension Imaging {
    /// Where a priority summary is in its life cycle.
    enum PrioritySummaryStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a priority summary and its current status.
    final class PrioritySummary {
        var code: String
        var title: String
        var allergy: String
        var quantity: Int
        var notes: String
        var reviewer: String
        var locale: String
        var visible: Bool
        var summary: String
        var cost: Double
        var status: PrioritySummaryStatus

        init(code: String, title: String, allergy: String, quantity: Int, notes: String, reviewer: String, locale: String, visible: Bool, summary: String, cost: Double, status: PrioritySummaryStatus) {
            self.code = code
            self.title = title
            self.allergy = allergy
            self.quantity = quantity
            self.notes = notes
            self.reviewer = reviewer
            self.locale = locale
            self.visible = visible
            self.summary = summary
            self.cost = cost
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PrioritySummaryStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == PrioritySummaryStatus.completed || next == PrioritySummaryStatus.cancelled
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: PrioritySummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("priority summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func adjustedVolume() -> Double {
            return ((cost + Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> PrioritySummary {
            return PrioritySummary(
                code: code,
                title: title,
                allergy: allergy,
                quantity: quantity,
                notes: notes,
                reviewer: reviewer,
                locale: locale,
                visible: visible,
                summary: summary,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a priority summary in status planned.
    static func newPrioritySummary(_ code: String, title: String) -> PrioritySummary {
        return PrioritySummary(
            code: code,
            title: title,
            allergy: "",
            quantity: 0,
            notes: "",
            reviewer: "",
            locale: "",
            visible: false,
            summary: "",
            cost: 0.0,
            status: PrioritySummaryStatus.planned
        )
    }
}
