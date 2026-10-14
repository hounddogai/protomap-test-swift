import AcmePlatform
import Foundation

extension Consent {
    /// Where a seasonal disclosure cycle is in its life cycle.
    enum SeasonalDisclosureCycleStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a seasonal disclosure cycle and its current status.
    final class SeasonalDisclosureCycle {
        var code: String
        var title: String
        var rate: Double
        var notes: String
        var acuity: Int
        var segment: String
        var category: String
        var archived: Bool
        var status: SeasonalDisclosureCycleStatus

        init(code: String, title: String, rate: Double, notes: String, acuity: Int, segment: String, category: String, archived: Bool, status: SeasonalDisclosureCycleStatus) {
            self.code = code
            self.title = title
            self.rate = rate
            self.notes = notes
            self.acuity = acuity
            self.segment = segment
            self.category = category
            self.archived = archived
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

        func canMoveTo(_ next: SeasonalDisclosureCycleStatus) -> Bool {
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
                return next == SeasonalDisclosureCycleStatus.completed
            case .inProgress:
                return next == SeasonalDisclosureCycleStatus.completed
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

        func moveTo(_ next: SeasonalDisclosureCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal disclosure cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("seasonal disclosure cycle") \(code)"
        }

        func netValue() -> Double {
            return ((Double(acuity) + rate) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalDisclosureCycle {
            return SeasonalDisclosureCycle(
                code: code,
                title: title,
                rate: rate,
                notes: notes,
                acuity: acuity,
                segment: segment,
                category: category,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a seasonal disclosure cycle in status planned.
    static func newSeasonalDisclosureCycle(_ code: String, title: String) -> SeasonalDisclosureCycle {
        return SeasonalDisclosureCycle(
            code: code,
            title: title,
            rate: 0.0,
            notes: "",
            acuity: 0,
            segment: "",
            category: "",
            archived: false,
            status: SeasonalDisclosureCycleStatus.planned
        )
    }
}
