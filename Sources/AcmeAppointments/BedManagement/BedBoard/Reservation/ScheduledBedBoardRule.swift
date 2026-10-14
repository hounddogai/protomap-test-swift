import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a scheduled bed board rule is in its life cycle.
    enum ScheduledBedBoardRuleStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A scheduled bed board rule. Its code is unique within a tenant.
    final class ScheduledBedBoardRule {
        var code: String
        var name: String
        var encounterID: String
        var threshold: Double
        var bed: String
        var graceDays: Int
        var checksum: String
        var revision: Int
        var maximum: Double
        var status: ScheduledBedBoardRuleStatus

        init(code: String, name: String, encounterID: String, threshold: Double, bed: String, graceDays: Int, checksum: String, revision: Int, maximum: Double, status: ScheduledBedBoardRuleStatus) {
            self.code = code
            self.name = name
            self.encounterID = encounterID
            self.threshold = threshold
            self.bed = bed
            self.graceDays = graceDays
            self.checksum = checksum
            self.revision = revision
            self.maximum = maximum
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

        func canMoveTo(_ next: ScheduledBedBoardRuleStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == ScheduledBedBoardRuleStatus.rejected || next == ScheduledBedBoardRuleStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: ScheduledBedBoardRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled bed board rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func adjustedLoad() -> Double {
            return (threshold * Double(graceDays) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledBedBoardRule {
            return ScheduledBedBoardRule(
                code: code,
                name: name,
                encounterID: encounterID,
                threshold: threshold,
                bed: bed,
                graceDays: graceDays,
                checksum: checksum,
                revision: revision,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a scheduled bed board rule in status proposed.
    static func newScheduledBedBoardRule(_ code: String, name: String) -> ScheduledBedBoardRule {
        return ScheduledBedBoardRule(
            code: code,
            name: name,
            encounterID: "",
            threshold: 0.0,
            bed: "",
            graceDays: 0,
            checksum: "",
            revision: 0,
            maximum: 0.0,
            status: ScheduledBedBoardRuleStatus.proposed
        )
    }
}
