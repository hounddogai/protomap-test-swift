import AcmePlatform
import Foundation

extension Labs {
    /// Where a seasonal reference range schedule is in its life cycle.
    enum SeasonalReferenceRangeScheduleStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a seasonal reference range schedule and its current status.
    final class SeasonalReferenceRangeSchedule {
        var code: String
        var title: String
        var retries: Int
        var threshold: Double
        var active: Bool
        var visible: Bool
        var rate: Double
        var status: SeasonalReferenceRangeScheduleStatus

        init(code: String, title: String, retries: Int, threshold: Double, active: Bool, visible: Bool, rate: Double, status: SeasonalReferenceRangeScheduleStatus) {
            self.code = code
            self.title = title
            self.retries = retries
            self.threshold = threshold
            self.active = active
            self.visible = visible
            self.rate = rate
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SeasonalReferenceRangeScheduleStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == SeasonalReferenceRangeScheduleStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: SeasonalReferenceRangeScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal reference range schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func weightedTotal() -> Double {
            return (threshold * rate * 100).rounded() / 100
        }

        func copyValue() -> SeasonalReferenceRangeSchedule {
            return SeasonalReferenceRangeSchedule(
                code: code,
                title: title,
                retries: retries,
                threshold: threshold,
                active: active,
                visible: visible,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a seasonal reference range schedule in status created.
    static func newSeasonalReferenceRangeSchedule(_ code: String, title: String) -> SeasonalReferenceRangeSchedule {
        return SeasonalReferenceRangeSchedule(
            code: code,
            title: title,
            retries: 0,
            threshold: 0.0,
            active: false,
            visible: false,
            rate: 0.0,
            status: SeasonalReferenceRangeScheduleStatus.created
        )
    }
}
