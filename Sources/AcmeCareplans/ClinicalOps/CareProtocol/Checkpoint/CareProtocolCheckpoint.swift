import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a care protocol checkpoint is in its life cycle.
    enum CareProtocolCheckpointStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One care protocol checkpoint, with what the planners need to act on it.
    final class CareProtocolCheckpoint {
        var code: String
        var name: String
        var unit: String
        var endsAt: Int
        var updatedAt: Int
        var ratio: Double
        var status: CareProtocolCheckpointStatus

        init(code: String, name: String, unit: String, endsAt: Int, updatedAt: Int, ratio: Double, status: CareProtocolCheckpointStatus) {
            self.code = code
            self.name = name
            self.unit = unit
            self.endsAt = endsAt
            self.updatedAt = updatedAt
            self.ratio = ratio
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

        func canMoveTo(_ next: CareProtocolCheckpointStatus) -> Bool {
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
                return next == CareProtocolCheckpointStatus.published || next == CareProtocolCheckpointStatus.retired
            case .published:
                return next == CareProtocolCheckpointStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareProtocolCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func effectiveValue() -> Double {
            return (Double(updatedAt) * ratio * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolCheckpoint {
            return CareProtocolCheckpoint(
                code: code,
                name: name,
                unit: unit,
                endsAt: endsAt,
                updatedAt: updatedAt,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a care protocol checkpoint in status created.
    static func newCareProtocolCheckpoint(_ code: String, name: String) -> CareProtocolCheckpoint {
        return CareProtocolCheckpoint(
            code: code,
            name: name,
            unit: "",
            endsAt: 0,
            updatedAt: 0,
            ratio: 0.0,
            status: CareProtocolCheckpointStatus.created
        )
    }
}
