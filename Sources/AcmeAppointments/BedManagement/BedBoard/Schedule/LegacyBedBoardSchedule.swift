import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a legacy bed board schedule is in its life cycle.
    enum LegacyBedBoardScheduleStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A legacy bed board schedule as the bed board team keeps it.
    final class LegacyBedBoardSchedule {
        var code: String
        var name: String
        var priority: Int
        var batchSize: Int
        var country: String
        var ceiling: Double
        var status: LegacyBedBoardScheduleStatus

        init(code: String, name: String, priority: Int, batchSize: Int, country: String, ceiling: Double, status: LegacyBedBoardScheduleStatus) {
            self.code = code
            self.name = name
            self.priority = priority
            self.batchSize = batchSize
            self.country = country
            self.ceiling = ceiling
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LegacyBedBoardScheduleStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == LegacyBedBoardScheduleStatus.running || next == LegacyBedBoardScheduleStatus.failed
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: LegacyBedBoardScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy bed board schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func netVolume() -> Double {
            return (ceiling * Double(priority) * 100).rounded() / 100
        }

        func copyValue() -> LegacyBedBoardSchedule {
            return LegacyBedBoardSchedule(
                code: code,
                name: name,
                priority: priority,
                batchSize: batchSize,
                country: country,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a legacy bed board schedule in status new.
    static func newLegacyBedBoardSchedule(_ code: String, name: String) -> LegacyBedBoardSchedule {
        return LegacyBedBoardSchedule(
            code: code,
            name: name,
            priority: 0,
            batchSize: 0,
            country: "",
            ceiling: 0.0,
            status: LegacyBedBoardScheduleStatus.new
        )
    }
}
