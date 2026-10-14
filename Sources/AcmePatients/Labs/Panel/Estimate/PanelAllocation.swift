import AcmePlatform
import Foundation

extension Labs {
    /// Where a panel allocation is in its life cycle.
    enum PanelAllocationStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A panel allocation as the panel team keeps it.
    final class PanelAllocation {
        var code: String
        var title: String
        var ward: String
        var priority: Int
        var active: Bool
        var budget: Double
        var createdAt: Int
        var externalRef: String
        var approved: Bool
        var status: PanelAllocationStatus

        init(code: String, title: String, ward: String, priority: Int, active: Bool, budget: Double, createdAt: Int, externalRef: String, approved: Bool, status: PanelAllocationStatus) {
            self.code = code
            self.title = title
            self.ward = ward
            self.priority = priority
            self.active = active
            self.budget = budget
            self.createdAt = createdAt
            self.externalRef = externalRef
            self.approved = approved
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PanelAllocationStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: PanelAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("panel allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("panel allocation") \(code)"
        }

        func adjustedValue() -> Double {
            return (Double(priority) * Double(createdAt) * 100).rounded() / 100
        }

        func copyValue() -> PanelAllocation {
            return PanelAllocation(
                code: code,
                title: title,
                ward: ward,
                priority: priority,
                active: active,
                budget: budget,
                createdAt: createdAt,
                externalRef: externalRef,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a panel allocation in status planned.
    static func newPanelAllocation(_ code: String, title: String) -> PanelAllocation {
        return PanelAllocation(
            code: code,
            title: title,
            ward: "",
            priority: 0,
            active: false,
            budget: 0.0,
            createdAt: 0,
            externalRef: "",
            approved: false,
            status: PanelAllocationStatus.planned
        )
    }
}
