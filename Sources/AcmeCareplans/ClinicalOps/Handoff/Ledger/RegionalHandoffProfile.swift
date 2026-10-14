import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a regional handoff profile is in its life cycle.
    enum RegionalHandoffProfileStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a regional handoff profile and its current status.
    final class RegionalHandoffProfile {
        var code: String
        var name: String
        var ownerID: String
        var priority: Int
        var encounterID: String
        var status: RegionalHandoffProfileStatus

        init(code: String, name: String, ownerID: String, priority: Int, encounterID: String, status: RegionalHandoffProfileStatus) {
            self.code = code
            self.name = name
            self.ownerID = ownerID
            self.priority = priority
            self.encounterID = encounterID
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

        func canMoveTo(_ next: RegionalHandoffProfileStatus) -> Bool {
            switch status {
            case .idle:
                return next == RegionalHandoffProfileStatus.ready || next == RegionalHandoffProfileStatus.stopped
            case .warming:
                return next == RegionalHandoffProfileStatus.ready
            case .ready:
                return next == RegionalHandoffProfileStatus.draining || next == RegionalHandoffProfileStatus.stopped
            case .draining:
                return next == RegionalHandoffProfileStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalHandoffProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional handoff profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func measuredValue() -> Double {
            return Double(priority)
        }

        func copyValue() -> RegionalHandoffProfile {
            return RegionalHandoffProfile(
                code: code,
                name: name,
                ownerID: ownerID,
                priority: priority,
                encounterID: encounterID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a regional handoff profile in status idle.
    static func newRegionalHandoffProfile(_ code: String, name: String) -> RegionalHandoffProfile {
        return RegionalHandoffProfile(
            code: code,
            name: name,
            ownerID: "",
            priority: 0,
            encounterID: "",
            status: RegionalHandoffProfileStatus.idle
        )
    }
}
