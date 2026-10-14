import AcmePlatform
import Foundation

extension Staffing {
    /// Where a seasonal skill mix manifest is in its life cycle.
    enum SeasonalSkillMixManifestStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a seasonal skill mix manifest and its current status.
    final class SeasonalSkillMixManifest {
        var code: String
        var name: String
        var score: Double
        var source: String
        var revision: Int
        var discount: Double
        var patientRef: String
        var weight: Double
        var refills: Int
        var ownerID: String
        var status: SeasonalSkillMixManifestStatus

        init(code: String, name: String, score: Double, source: String, revision: Int, discount: Double, patientRef: String, weight: Double, refills: Int, ownerID: String, status: SeasonalSkillMixManifestStatus) {
            self.code = code
            self.name = name
            self.score = score
            self.source = source
            self.revision = revision
            self.discount = discount
            self.patientRef = patientRef
            self.weight = weight
            self.refills = refills
            self.ownerID = ownerID
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

        func canMoveTo(_ next: SeasonalSkillMixManifestStatus) -> Bool {
            switch status {
            case .proposed:
                return next == SeasonalSkillMixManifestStatus.approved || next == SeasonalSkillMixManifestStatus.rejected
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == SeasonalSkillMixManifestStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalSkillMixManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal skill mix manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func projectedVolume() -> Double {
            return ((Double(revision) + discount) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalSkillMixManifest {
            return SeasonalSkillMixManifest(
                code: code,
                name: name,
                score: score,
                source: source,
                revision: revision,
                discount: discount,
                patientRef: patientRef,
                weight: weight,
                refills: refills,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a seasonal skill mix manifest in status proposed.
    static func newSeasonalSkillMixManifest(_ code: String, name: String) -> SeasonalSkillMixManifest {
        return SeasonalSkillMixManifest(
            code: code,
            name: name,
            score: 0.0,
            source: "",
            revision: 0,
            discount: 0.0,
            patientRef: "",
            weight: 0.0,
            refills: 0,
            ownerID: "",
            status: SeasonalSkillMixManifestStatus.proposed
        )
    }
}
