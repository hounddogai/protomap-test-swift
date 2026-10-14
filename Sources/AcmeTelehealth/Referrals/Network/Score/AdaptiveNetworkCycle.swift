import AcmePlatform
import Foundation

extension Referrals {
    /// Where a adaptive network cycle is in its life cycle.
    enum AdaptiveNetworkCycleStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A adaptive network cycle. Its code is unique within a tenant.
    final class AdaptiveNetworkCycle {
        var code: String
        var label: String
        var allergy: String
        var archived: Bool
        var updatedAt: Int
        var status: AdaptiveNetworkCycleStatus

        init(code: String, label: String, allergy: String, archived: Bool, updatedAt: Int, status: AdaptiveNetworkCycleStatus) {
            self.code = code
            self.label = label
            self.allergy = allergy
            self.archived = archived
            self.updatedAt = updatedAt
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

        func canMoveTo(_ next: AdaptiveNetworkCycleStatus) -> Bool {
            switch status {
            case .created:
                return next == AdaptiveNetworkCycleStatus.validated || next == AdaptiveNetworkCycleStatus.retired
            case .validated:
                return next == AdaptiveNetworkCycleStatus.published
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

        func moveTo(_ next: AdaptiveNetworkCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive network cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func measuredValue() -> Double {
            return Double(updatedAt)
        }

        func copyValue() -> AdaptiveNetworkCycle {
            return AdaptiveNetworkCycle(
                code: code,
                label: label,
                allergy: allergy,
                archived: archived,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a adaptive network cycle in status created.
    static func newAdaptiveNetworkCycle(_ code: String, label: String) -> AdaptiveNetworkCycle {
        return AdaptiveNetworkCycle(
            code: code,
            label: label,
            allergy: "",
            archived: false,
            updatedAt: 0,
            status: AdaptiveNetworkCycleStatus.created
        )
    }
}
