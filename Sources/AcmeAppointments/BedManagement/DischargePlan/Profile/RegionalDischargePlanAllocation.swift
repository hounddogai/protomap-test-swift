import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a regional discharge plan allocation is in its life cycle.
    enum RegionalDischargePlanAllocationStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One regional discharge plan allocation, with what the planners need to act on it.
    final class RegionalDischargePlanAllocation {
        var code: String
        var label: String
        var checksum: String
        var encounterID: String
        var windowDays: Int
        var status: RegionalDischargePlanAllocationStatus

        init(code: String, label: String, checksum: String, encounterID: String, windowDays: Int, status: RegionalDischargePlanAllocationStatus) {
            self.code = code
            self.label = label
            self.checksum = checksum
            self.encounterID = encounterID
            self.windowDays = windowDays
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RegionalDischargePlanAllocationStatus) -> Bool {
            switch status {
            case .`open`:
                return next == RegionalDischargePlanAllocationStatus.resolved
            case .inReview:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == RegionalDischargePlanAllocationStatus.reopened
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: RegionalDischargePlanAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional discharge plan allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func measuredValue() -> Double {
            return Double(windowDays)
        }

        func copyValue() -> RegionalDischargePlanAllocation {
            return RegionalDischargePlanAllocation(
                code: code,
                label: label,
                checksum: checksum,
                encounterID: encounterID,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a regional discharge plan allocation in status open.
    static func newRegionalDischargePlanAllocation(_ code: String, label: String) -> RegionalDischargePlanAllocation {
        return RegionalDischargePlanAllocation(
            code: code,
            label: label,
            checksum: "",
            encounterID: "",
            windowDays: 0,
            status: RegionalDischargePlanAllocationStatus.`open`
        )
    }
}
