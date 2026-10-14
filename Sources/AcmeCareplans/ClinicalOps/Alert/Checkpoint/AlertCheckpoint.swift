import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a alert checkpoint is in its life cycle.
    enum AlertCheckpointStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a alert checkpoint and its current status.
    final class AlertCheckpoint {
        var code: String
        var name: String
        var limit: Int
        var cost: Double
        var endsAt: Int
        var visible: Bool
        var floorValue: Double
        var status: AlertCheckpointStatus

        init(code: String, name: String, limit: Int, cost: Double, endsAt: Int, visible: Bool, floorValue: Double, status: AlertCheckpointStatus) {
            self.code = code
            self.name = name
            self.limit = limit
            self.cost = cost
            self.endsAt = endsAt
            self.visible = visible
            self.floorValue = floorValue
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

        func canMoveTo(_ next: AlertCheckpointStatus) -> Bool {
            switch status {
            case .planned:
                return next == AlertCheckpointStatus.cancelled
            case .scheduled:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed:
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

        func moveTo(_ next: AlertCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("alert checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func adjustedTotal() -> Double {
            return ((floorValue + Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> AlertCheckpoint {
            return AlertCheckpoint(
                code: code,
                name: name,
                limit: limit,
                cost: cost,
                endsAt: endsAt,
                visible: visible,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a alert checkpoint in status planned.
    static func newAlertCheckpoint(_ code: String, name: String) -> AlertCheckpoint {
        return AlertCheckpoint(
            code: code,
            name: name,
            limit: 0,
            cost: 0.0,
            endsAt: 0,
            visible: false,
            floorValue: 0.0,
            status: AlertCheckpointStatus.planned
        )
    }
}
