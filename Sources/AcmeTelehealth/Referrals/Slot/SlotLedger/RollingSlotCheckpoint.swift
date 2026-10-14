import AcmePlatform
import Foundation

extension Referrals {
    /// Where a rolling slot checkpoint is in its life cycle.
    enum RollingSlotCheckpointStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A rolling slot checkpoint as the slot team keeps it.
    final class RollingSlotCheckpoint {
        var code: String
        var name: String
        var ward: String
        var sequence: Int
        var timezone: String
        var budget: Double
        var attributes: [String: String]
        var updatedAt: Int
        var status: RollingSlotCheckpointStatus

        init(code: String, name: String, ward: String, sequence: Int, timezone: String, budget: Double, attributes: [String: String], updatedAt: Int, status: RollingSlotCheckpointStatus) {
            self.code = code
            self.name = name
            self.ward = ward
            self.sequence = sequence
            self.timezone = timezone
            self.budget = budget
            self.attributes = attributes
            self.updatedAt = updatedAt
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

        func canMoveTo(_ next: RollingSlotCheckpointStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == RollingSlotCheckpointStatus.inProgress || next == RollingSlotCheckpointStatus.cancelled
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == RollingSlotCheckpointStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingSlotCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling slot checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func projectedTotal() -> Double {
            return (budget * Double(sequence) * 100).rounded() / 100
        }

        func copyValue() -> RollingSlotCheckpoint {
            return RollingSlotCheckpoint(
                code: code,
                name: name,
                ward: ward,
                sequence: sequence,
                timezone: timezone,
                budget: budget,
                attributes: attributes,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a rolling slot checkpoint in status planned.
    static func newRollingSlotCheckpoint(_ code: String, name: String) -> RollingSlotCheckpoint {
        return RollingSlotCheckpoint(
            code: code,
            name: name,
            ward: "",
            sequence: 0,
            timezone: "",
            budget: 0.0,
            attributes: [:],
            updatedAt: 0,
            status: RollingSlotCheckpointStatus.planned
        )
    }
}
