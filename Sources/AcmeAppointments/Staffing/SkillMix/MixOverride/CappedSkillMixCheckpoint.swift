import AcmePlatform
import Foundation

extension Staffing {
    /// Where a capped skill mix checkpoint is in its life cycle.
    enum CappedSkillMixCheckpointStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One capped skill mix checkpoint, with what the planners need to act on it.
    final class CappedSkillMixCheckpoint {
        var code: String
        var name: String
        var dosageMg: Double
        var version: Int
        var sequence: Int
        var ratio: Double
        var threshold: Double
        var createdAt: Int
        var startsAt: Int
        var encounterID: String
        var status: CappedSkillMixCheckpointStatus

        init(code: String, name: String, dosageMg: Double, version: Int, sequence: Int, ratio: Double, threshold: Double, createdAt: Int, startsAt: Int, encounterID: String, status: CappedSkillMixCheckpointStatus) {
            self.code = code
            self.name = name
            self.dosageMg = dosageMg
            self.version = version
            self.sequence = sequence
            self.ratio = ratio
            self.threshold = threshold
            self.createdAt = createdAt
            self.startsAt = startsAt
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

        func canMoveTo(_ next: CappedSkillMixCheckpointStatus) -> Bool {
            switch status {
            case .proposed:
                return next == CappedSkillMixCheckpointStatus.approved
            case .approved:
                return next == CappedSkillMixCheckpointStatus.rejected || next == CappedSkillMixCheckpointStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: CappedSkillMixCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped skill mix checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func netVolume() -> Double {
            return ((Double(version) + dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> CappedSkillMixCheckpoint {
            return CappedSkillMixCheckpoint(
                code: code,
                name: name,
                dosageMg: dosageMg,
                version: version,
                sequence: sequence,
                ratio: ratio,
                threshold: threshold,
                createdAt: createdAt,
                startsAt: startsAt,
                encounterID: encounterID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a capped skill mix checkpoint in status proposed.
    static func newCappedSkillMixCheckpoint(_ code: String, name: String) -> CappedSkillMixCheckpoint {
        return CappedSkillMixCheckpoint(
            code: code,
            name: name,
            dosageMg: 0.0,
            version: 0,
            sequence: 0,
            ratio: 0.0,
            threshold: 0.0,
            createdAt: 0,
            startsAt: 0,
            encounterID: "",
            status: CappedSkillMixCheckpointStatus.proposed
        )
    }
}
