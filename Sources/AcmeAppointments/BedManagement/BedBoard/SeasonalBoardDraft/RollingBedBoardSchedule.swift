import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a rolling bed board schedule is in its life cycle.
    enum RollingBedBoardScheduleStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A rolling bed board schedule as the bed board team keeps it.
    final class RollingBedBoardSchedule {
        var code: String
        var label: String
        var startsAt: Int
        var threshold: Double
        var amount: Double
        var segment: String
        var graceDays: Int
        var budget: Double
        var minimum: Double
        var checksum: String
        var status: RollingBedBoardScheduleStatus

        init(code: String, label: String, startsAt: Int, threshold: Double, amount: Double, segment: String, graceDays: Int, budget: Double, minimum: Double, checksum: String, status: RollingBedBoardScheduleStatus) {
            self.code = code
            self.label = label
            self.startsAt = startsAt
            self.threshold = threshold
            self.amount = amount
            self.segment = segment
            self.graceDays = graceDays
            self.budget = budget
            self.minimum = minimum
            self.checksum = checksum
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

        func canMoveTo(_ next: RollingBedBoardScheduleStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == RollingBedBoardScheduleStatus.ready || next == RollingBedBoardScheduleStatus.draining
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == RollingBedBoardScheduleStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingBedBoardScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling bed board schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("rolling bed board schedule") \(code)"
        }

        func effectiveTotal() -> Double {
            return (budget * threshold * 100).rounded() / 100
        }

        func copyValue() -> RollingBedBoardSchedule {
            return RollingBedBoardSchedule(
                code: code,
                label: label,
                startsAt: startsAt,
                threshold: threshold,
                amount: amount,
                segment: segment,
                graceDays: graceDays,
                budget: budget,
                minimum: minimum,
                checksum: checksum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a rolling bed board schedule in status idle.
    static func newRollingBedBoardSchedule(_ code: String, label: String) -> RollingBedBoardSchedule {
        return RollingBedBoardSchedule(
            code: code,
            label: label,
            startsAt: 0,
            threshold: 0.0,
            amount: 0.0,
            segment: "",
            graceDays: 0,
            budget: 0.0,
            minimum: 0.0,
            checksum: "",
            status: RollingBedBoardScheduleStatus.idle
        )
    }
}
