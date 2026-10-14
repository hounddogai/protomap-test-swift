import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a scheduled task summary is in its life cycle.
    enum ScheduledTaskSummaryStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A scheduled task summary. Its code is unique within a tenant.
    final class ScheduledTaskSummary {
        var code: String
        var label: String
        var bed: String
        var amount: Double
        var facility: String
        var startsAt: Int
        var updatedAt: Int
        var status: ScheduledTaskSummaryStatus

        init(code: String, label: String, bed: String, amount: Double, facility: String, startsAt: Int, updatedAt: Int, status: ScheduledTaskSummaryStatus) {
            self.code = code
            self.label = label
            self.bed = bed
            self.amount = amount
            self.facility = facility
            self.startsAt = startsAt
            self.updatedAt = updatedAt
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

        func canMoveTo(_ next: ScheduledTaskSummaryStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .ready:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .draining:
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
                switch next {
                case .stopped:
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

        func moveTo(_ next: ScheduledTaskSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled task summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("scheduled task summary") \(code)"
        }

        func effectiveTotal() -> Double {
            return (Double(updatedAt) * Double(startsAt) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledTaskSummary {
            return ScheduledTaskSummary(
                code: code,
                label: label,
                bed: bed,
                amount: amount,
                facility: facility,
                startsAt: startsAt,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a scheduled task summary in status idle.
    static func newScheduledTaskSummary(_ code: String, label: String) -> ScheduledTaskSummary {
        return ScheduledTaskSummary(
            code: code,
            label: label,
            bed: "",
            amount: 0.0,
            facility: "",
            startsAt: 0,
            updatedAt: 0,
            status: ScheduledTaskSummaryStatus.idle
        )
    }
}
