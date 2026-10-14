import AcmePlatform
import Foundation

extension Referrals {
    /// Where a seasonal network group is in its life cycle.
    enum SeasonalNetworkGroupStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A seasonal network group as the network team keeps it.
    final class SeasonalNetworkGroup {
        var code: String
        var title: String
        var ceiling: Double
        var budget: Double
        var weight: Double
        var priority: Int
        var approved: Bool
        var encounterID: String
        var copay: Double
        var status: SeasonalNetworkGroupStatus

        init(code: String, title: String, ceiling: Double, budget: Double, weight: Double, priority: Int, approved: Bool, encounterID: String, copay: Double, status: SeasonalNetworkGroupStatus) {
            self.code = code
            self.title = title
            self.ceiling = ceiling
            self.budget = budget
            self.weight = weight
            self.priority = priority
            self.approved = approved
            self.encounterID = encounterID
            self.copay = copay
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SeasonalNetworkGroupStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == SeasonalNetworkGroupStatus.published || next == SeasonalNetworkGroupStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: SeasonalNetworkGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal network group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func effectiveExposure() -> Double {
            return ((ceiling + copay) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalNetworkGroup {
            return SeasonalNetworkGroup(
                code: code,
                title: title,
                ceiling: ceiling,
                budget: budget,
                weight: weight,
                priority: priority,
                approved: approved,
                encounterID: encounterID,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a seasonal network group in status created.
    static func newSeasonalNetworkGroup(_ code: String, title: String) -> SeasonalNetworkGroup {
        return SeasonalNetworkGroup(
            code: code,
            title: title,
            ceiling: 0.0,
            budget: 0.0,
            weight: 0.0,
            priority: 0,
            approved: false,
            encounterID: "",
            copay: 0.0,
            status: SeasonalNetworkGroupStatus.created
        )
    }
}
