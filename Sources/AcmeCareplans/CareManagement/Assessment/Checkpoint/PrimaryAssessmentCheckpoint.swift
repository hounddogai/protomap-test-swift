import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a primary assessment checkpoint is in its life cycle.
    enum PrimaryAssessmentCheckpointStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A primary assessment checkpoint. Its code is unique within a tenant.
    final class PrimaryAssessmentCheckpoint {
        var code: String
        var name: String
        var floorValue: Double
        var score: Double
        var version: Int
        var currency: String
        var allergy: String
        var revision: Int
        var sequence: Int
        var status: PrimaryAssessmentCheckpointStatus

        init(code: String, name: String, floorValue: Double, score: Double, version: Int, currency: String, allergy: String, revision: Int, sequence: Int, status: PrimaryAssessmentCheckpointStatus) {
            self.code = code
            self.name = name
            self.floorValue = floorValue
            self.score = score
            self.version = version
            self.currency = currency
            self.allergy = allergy
            self.revision = revision
            self.sequence = sequence
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PrimaryAssessmentCheckpointStatus) -> Bool {
            switch status {
            case .new:
                return next == PrimaryAssessmentCheckpointStatus.running
            case .queued:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == PrimaryAssessmentCheckpointStatus.failed
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: PrimaryAssessmentCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary assessment checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func weightedValue() -> Double {
            return ((Double(version) + Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryAssessmentCheckpoint {
            return PrimaryAssessmentCheckpoint(
                code: code,
                name: name,
                floorValue: floorValue,
                score: score,
                version: version,
                currency: currency,
                allergy: allergy,
                revision: revision,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a primary assessment checkpoint in status new.
    static func newPrimaryAssessmentCheckpoint(_ code: String, name: String) -> PrimaryAssessmentCheckpoint {
        return PrimaryAssessmentCheckpoint(
            code: code,
            name: name,
            floorValue: 0.0,
            score: 0.0,
            version: 0,
            currency: "",
            allergy: "",
            revision: 0,
            sequence: 0,
            status: PrimaryAssessmentCheckpointStatus.new
        )
    }
}
