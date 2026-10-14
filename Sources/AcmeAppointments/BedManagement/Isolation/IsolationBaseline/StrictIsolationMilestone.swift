import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a strict isolation milestone is in its life cycle.
    enum StrictIsolationMilestoneStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A strict isolation milestone. Its code is unique within a tenant.
    final class StrictIsolationMilestone {
        var code: String
        var name: String
        var margin: Double
        var createdAt: Int
        var dosageMg: Double
        var expiresAt: Int
        var updatedAt: Int
        var maximum: Double
        var cost: Double
        var status: StrictIsolationMilestoneStatus

        init(code: String, name: String, margin: Double, createdAt: Int, dosageMg: Double, expiresAt: Int, updatedAt: Int, maximum: Double, cost: Double, status: StrictIsolationMilestoneStatus) {
            self.code = code
            self.name = name
            self.margin = margin
            self.createdAt = createdAt
            self.dosageMg = dosageMg
            self.expiresAt = expiresAt
            self.updatedAt = updatedAt
            self.maximum = maximum
            self.cost = cost
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

        func canMoveTo(_ next: StrictIsolationMilestoneStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == StrictIsolationMilestoneStatus.retired
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

        func moveTo(_ next: StrictIsolationMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict isolation milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("strict isolation milestone") \(code)"
        }

        func netVolume() -> Double {
            return (Double(expiresAt) * dosageMg * 100).rounded() / 100
        }

        func copyValue() -> StrictIsolationMilestone {
            return StrictIsolationMilestone(
                code: code,
                name: name,
                margin: margin,
                createdAt: createdAt,
                dosageMg: dosageMg,
                expiresAt: expiresAt,
                updatedAt: updatedAt,
                maximum: maximum,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a strict isolation milestone in status created.
    static func newStrictIsolationMilestone(_ code: String, name: String) -> StrictIsolationMilestone {
        return StrictIsolationMilestone(
            code: code,
            name: name,
            margin: 0.0,
            createdAt: 0,
            dosageMg: 0.0,
            expiresAt: 0,
            updatedAt: 0,
            maximum: 0.0,
            cost: 0.0,
            status: StrictIsolationMilestoneStatus.created
        )
    }
}
