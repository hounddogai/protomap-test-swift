import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a manual claim milestone is in its life cycle.
    enum ManualClaimMilestoneStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A manual claim milestone. Its code is unique within a tenant.
    final class ManualClaimMilestone {
        var code: String
        var name: String
        var active: Bool
        var windowDays: Int
        var batchSize: Int
        var status: ManualClaimMilestoneStatus

        init(code: String, name: String, active: Bool, windowDays: Int, batchSize: Int, status: ManualClaimMilestoneStatus) {
            self.code = code
            self.name = name
            self.active = active
            self.windowDays = windowDays
            self.batchSize = batchSize
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

        func canMoveTo(_ next: ManualClaimMilestoneStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == ManualClaimMilestoneStatus.published || next == ManualClaimMilestoneStatus.retired
            case .published:
                return next == ManualClaimMilestoneStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualClaimMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual claim milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func adjustedVolume() -> Double {
            return ((Double(windowDays) + Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> ManualClaimMilestone {
            return ManualClaimMilestone(
                code: code,
                name: name,
                active: active,
                windowDays: windowDays,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a manual claim milestone in status created.
    static func newManualClaimMilestone(_ code: String, name: String) -> ManualClaimMilestone {
        return ManualClaimMilestone(
            code: code,
            name: name,
            active: false,
            windowDays: 0,
            batchSize: 0,
            status: ManualClaimMilestoneStatus.created
        )
    }
}
