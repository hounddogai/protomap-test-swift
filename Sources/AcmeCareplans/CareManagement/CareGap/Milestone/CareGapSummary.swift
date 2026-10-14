import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a care gap summary is in its life cycle.
    enum CareGapSummaryStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A care gap summary as the care gap team keeps it.
    final class CareGapSummary {
        var code: String
        var title: String
        var weight: Double
        var notes: String
        var description: String
        var windowDays: Int
        var archived: Bool
        var graceDays: Int
        var approved: Bool
        var status: CareGapSummaryStatus

        init(code: String, title: String, weight: Double, notes: String, description: String, windowDays: Int, archived: Bool, graceDays: Int, approved: Bool, status: CareGapSummaryStatus) {
            self.code = code
            self.title = title
            self.weight = weight
            self.notes = notes
            self.description = description
            self.windowDays = windowDays
            self.archived = archived
            self.graceDays = graceDays
            self.approved = approved
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

        func canMoveTo(_ next: CareGapSummaryStatus) -> Bool {
            switch status {
            case .idle:
                return next == CareGapSummaryStatus.ready
            case .warming:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == CareGapSummaryStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareGapSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care gap summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("care gap summary") \(code)"
        }

        func netLoad() -> Double {
            return (weight * Double(graceDays) * 100).rounded() / 100
        }

        func copyValue() -> CareGapSummary {
            return CareGapSummary(
                code: code,
                title: title,
                weight: weight,
                notes: notes,
                description: description,
                windowDays: windowDays,
                archived: archived,
                graceDays: graceDays,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a care gap summary in status idle.
    static func newCareGapSummary(_ code: String, title: String) -> CareGapSummary {
        return CareGapSummary(
            code: code,
            title: title,
            weight: 0.0,
            notes: "",
            description: "",
            windowDays: 0,
            archived: false,
            graceDays: 0,
            approved: false,
            status: CareGapSummaryStatus.idle
        )
    }
}
