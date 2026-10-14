import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a global outreach allocation is in its life cycle.
    enum GlobalOutreachAllocationStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A global outreach allocation as the outreach team keeps it.
    final class GlobalOutreachAllocation {
        var code: String
        var label: String
        var limit: Int
        var region: String
        var startsAt: Int
        var windowDays: Int
        var ownerID: String
        var payer: String
        var encounterID: String
        var visitMinutes: Int
        var floorValue: Double
        var status: GlobalOutreachAllocationStatus

        init(code: String, label: String, limit: Int, region: String, startsAt: Int, windowDays: Int, ownerID: String, payer: String, encounterID: String, visitMinutes: Int, floorValue: Double, status: GlobalOutreachAllocationStatus) {
            self.code = code
            self.label = label
            self.limit = limit
            self.region = region
            self.startsAt = startsAt
            self.windowDays = windowDays
            self.ownerID = ownerID
            self.payer = payer
            self.encounterID = encounterID
            self.visitMinutes = visitMinutes
            self.floorValue = floorValue
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

        func canMoveTo(_ next: GlobalOutreachAllocationStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == GlobalOutreachAllocationStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalOutreachAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global outreach allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func projectedValue() -> Double {
            return ((Double(limit) + Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> GlobalOutreachAllocation {
            return GlobalOutreachAllocation(
                code: code,
                label: label,
                limit: limit,
                region: region,
                startsAt: startsAt,
                windowDays: windowDays,
                ownerID: ownerID,
                payer: payer,
                encounterID: encounterID,
                visitMinutes: visitMinutes,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a global outreach allocation in status idle.
    static func newGlobalOutreachAllocation(_ code: String, label: String) -> GlobalOutreachAllocation {
        return GlobalOutreachAllocation(
            code: code,
            label: label,
            limit: 0,
            region: "",
            startsAt: 0,
            windowDays: 0,
            ownerID: "",
            payer: "",
            encounterID: "",
            visitMinutes: 0,
            floorValue: 0.0,
            status: GlobalOutreachAllocationStatus.idle
        )
    }
}
