import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a global denial cycle is in its life cycle.
    enum GlobalDenialCycleStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One global denial cycle, with what the planners need to act on it.
    final class GlobalDenialCycle {
        var code: String
        var name: String
        var maximum: Double
        var encounterID: String
        var ownerID: String
        var updatedAt: Int
        var retries: Int
        var status: GlobalDenialCycleStatus

        init(code: String, name: String, maximum: Double, encounterID: String, ownerID: String, updatedAt: Int, retries: Int, status: GlobalDenialCycleStatus) {
            self.code = code
            self.name = name
            self.maximum = maximum
            self.encounterID = encounterID
            self.ownerID = ownerID
            self.updatedAt = updatedAt
            self.retries = retries
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

        func canMoveTo(_ next: GlobalDenialCycleStatus) -> Bool {
            switch status {
            case .proposed:
                return next == GlobalDenialCycleStatus.approved || next == GlobalDenialCycleStatus.withdrawn
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: GlobalDenialCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global denial cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("global denial cycle") \(code)"
        }

        func projectedVolume() -> Double {
            return ((Double(updatedAt) - maximum) * 100).rounded() / 100
        }

        func copyValue() -> GlobalDenialCycle {
            return GlobalDenialCycle(
                code: code,
                name: name,
                maximum: maximum,
                encounterID: encounterID,
                ownerID: ownerID,
                updatedAt: updatedAt,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a global denial cycle in status proposed.
    static func newGlobalDenialCycle(_ code: String, name: String) -> GlobalDenialCycle {
        return GlobalDenialCycle(
            code: code,
            name: name,
            maximum: 0.0,
            encounterID: "",
            ownerID: "",
            updatedAt: 0,
            retries: 0,
            status: GlobalDenialCycleStatus.proposed
        )
    }
}
