import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a pending goal preference is in its life cycle.
    enum PendingGoalPreferenceStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One pending goal preference, with what the planners need to act on it.
    final class PendingGoalPreference {
        var code: String
        var name: String
        var cost: Double
        var refills: Int
        var minimum: Double
        var region: String
        var reviewer: String
        var encounterID: String
        var status: PendingGoalPreferenceStatus

        init(code: String, name: String, cost: Double, refills: Int, minimum: Double, region: String, reviewer: String, encounterID: String, status: PendingGoalPreferenceStatus) {
            self.code = code
            self.name = name
            self.cost = cost
            self.refills = refills
            self.minimum = minimum
            self.region = region
            self.reviewer = reviewer
            self.encounterID = encounterID
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

        func canMoveTo(_ next: PendingGoalPreferenceStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == PendingGoalPreferenceStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingGoalPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending goal preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func weightedVolume() -> Double {
            return (minimum * cost * 100).rounded() / 100
        }

        func copyValue() -> PendingGoalPreference {
            return PendingGoalPreference(
                code: code,
                name: name,
                cost: cost,
                refills: refills,
                minimum: minimum,
                region: region,
                reviewer: reviewer,
                encounterID: encounterID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a pending goal preference in status proposed.
    static func newPendingGoalPreference(_ code: String, name: String) -> PendingGoalPreference {
        return PendingGoalPreference(
            code: code,
            name: name,
            cost: 0.0,
            refills: 0,
            minimum: 0.0,
            region: "",
            reviewer: "",
            encounterID: "",
            status: PendingGoalPreferenceStatus.proposed
        )
    }
}
