import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a weighted formulary profile is in its life cycle.
    enum WeightedFormularyProfileStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A weighted formulary profile. Its code is unique within a tenant.
    final class WeightedFormularyProfile {
        var code: String
        var label: String
        var tags: [String]
        var retries: Int
        var clinicianID: String
        var score: Double
        var encounterID: String
        var status: WeightedFormularyProfileStatus

        init(code: String, label: String, tags: [String], retries: Int, clinicianID: String, score: Double, encounterID: String, status: WeightedFormularyProfileStatus) {
            self.code = code
            self.label = label
            self.tags = tags
            self.retries = retries
            self.clinicianID = clinicianID
            self.score = score
            self.encounterID = encounterID
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

        func canMoveTo(_ next: WeightedFormularyProfileStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == WeightedFormularyProfileStatus.active
            case .active:
                return next == WeightedFormularyProfileStatus.suspended
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

        func moveTo(_ next: WeightedFormularyProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted formulary profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("weighted formulary profile") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func projectedVolume() -> Double {
            return ((Double(retries) + score) * 100).rounded() / 100
        }

        func copyValue() -> WeightedFormularyProfile {
            return WeightedFormularyProfile(
                code: code,
                label: label,
                tags: tags,
                retries: retries,
                clinicianID: clinicianID,
                score: score,
                encounterID: encounterID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a weighted formulary profile in status draft.
    static func newWeightedFormularyProfile(_ code: String, label: String) -> WeightedFormularyProfile {
        return WeightedFormularyProfile(
            code: code,
            label: label,
            tags: [],
            retries: 0,
            clinicianID: "",
            score: 0.0,
            encounterID: "",
            status: WeightedFormularyProfileStatus.draft
        )
    }
}
