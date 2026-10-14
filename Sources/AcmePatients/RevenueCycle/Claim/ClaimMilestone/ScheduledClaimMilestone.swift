import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a scheduled claim milestone is in its life cycle.
    enum ScheduledClaimMilestoneStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a scheduled claim milestone and its current status.
    final class ScheduledClaimMilestone {
        var code: String
        var name: String
        var quantity: Int
        var durationMinutes: Int
        var source: String
        var unit: String
        var region: String
        var status: ScheduledClaimMilestoneStatus

        init(code: String, name: String, quantity: Int, durationMinutes: Int, source: String, unit: String, region: String, status: ScheduledClaimMilestoneStatus) {
            self.code = code
            self.name = name
            self.quantity = quantity
            self.durationMinutes = durationMinutes
            self.source = source
            self.unit = unit
            self.region = region
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ScheduledClaimMilestoneStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == ScheduledClaimMilestoneStatus.closed
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: ScheduledClaimMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled claim milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func adjustedLoad() -> Double {
            return ((Double(durationMinutes) - Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledClaimMilestone {
            return ScheduledClaimMilestone(
                code: code,
                name: name,
                quantity: quantity,
                durationMinutes: durationMinutes,
                source: source,
                unit: unit,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a scheduled claim milestone in status draft.
    static func newScheduledClaimMilestone(_ code: String, name: String) -> ScheduledClaimMilestone {
        return ScheduledClaimMilestone(
            code: code,
            name: name,
            quantity: 0,
            durationMinutes: 0,
            source: "",
            unit: "",
            region: "",
            status: ScheduledClaimMilestoneStatus.draft
        )
    }
}
