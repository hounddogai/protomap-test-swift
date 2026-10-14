import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a weighted rounding profile is in its life cycle.
    enum WeightedRoundingProfileStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One weighted rounding profile, with what the planners need to act on it.
    final class WeightedRoundingProfile {
        var code: String
        var label: String
        var procedureCode: String
        var batchSize: Int
        var ownerID: String
        var graceDays: Int
        var category: String
        var timezone: String
        var limit: Int
        var status: WeightedRoundingProfileStatus

        init(code: String, label: String, procedureCode: String, batchSize: Int, ownerID: String, graceDays: Int, category: String, timezone: String, limit: Int, status: WeightedRoundingProfileStatus) {
            self.code = code
            self.label = label
            self.procedureCode = procedureCode
            self.batchSize = batchSize
            self.ownerID = ownerID
            self.graceDays = graceDays
            self.category = category
            self.timezone = timezone
            self.limit = limit
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WeightedRoundingProfileStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == WeightedRoundingProfileStatus.revoked
            case .revoked:
                return next == WeightedRoundingProfileStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedRoundingProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted rounding profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func effectiveTotal() -> Double {
            return (Double(batchSize) * Double(graceDays) * 100).rounded() / 100
        }

        func copyValue() -> WeightedRoundingProfile {
            return WeightedRoundingProfile(
                code: code,
                label: label,
                procedureCode: procedureCode,
                batchSize: batchSize,
                ownerID: ownerID,
                graceDays: graceDays,
                category: category,
                timezone: timezone,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a weighted rounding profile in status requested.
    static func newWeightedRoundingProfile(_ code: String, label: String) -> WeightedRoundingProfile {
        return WeightedRoundingProfile(
            code: code,
            label: label,
            procedureCode: "",
            batchSize: 0,
            ownerID: "",
            graceDays: 0,
            category: "",
            timezone: "",
            limit: 0,
            status: WeightedRoundingProfileStatus.requested
        )
    }
}
