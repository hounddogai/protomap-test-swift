import AcmePlatform
import Foundation

extension Staffing {
    /// Where a legacy credential schedule is in its life cycle.
    enum LegacyCredentialScheduleStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One legacy credential schedule, with what the planners need to act on it.
    final class LegacyCredentialSchedule {
        var code: String
        var label: String
        var batchSize: Int
        var procedureCode: String
        var bed: String
        var rate: Double
        var ceiling: Double
        var approved: Bool
        var status: LegacyCredentialScheduleStatus

        init(code: String, label: String, batchSize: Int, procedureCode: String, bed: String, rate: Double, ceiling: Double, approved: Bool, status: LegacyCredentialScheduleStatus) {
            self.code = code
            self.label = label
            self.batchSize = batchSize
            self.procedureCode = procedureCode
            self.bed = bed
            self.rate = rate
            self.ceiling = ceiling
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

        func canMoveTo(_ next: LegacyCredentialScheduleStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == LegacyCredentialScheduleStatus.draining || next == LegacyCredentialScheduleStatus.stopped
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == LegacyCredentialScheduleStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyCredentialScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy credential schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func netVolume() -> Double {
            return ((Double(batchSize) - rate) * 100).rounded() / 100
        }

        func copyValue() -> LegacyCredentialSchedule {
            return LegacyCredentialSchedule(
                code: code,
                label: label,
                batchSize: batchSize,
                procedureCode: procedureCode,
                bed: bed,
                rate: rate,
                ceiling: ceiling,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a legacy credential schedule in status idle.
    static func newLegacyCredentialSchedule(_ code: String, label: String) -> LegacyCredentialSchedule {
        return LegacyCredentialSchedule(
            code: code,
            label: label,
            batchSize: 0,
            procedureCode: "",
            bed: "",
            rate: 0.0,
            ceiling: 0.0,
            approved: false,
            status: LegacyCredentialScheduleStatus.idle
        )
    }
}
