import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a seasonal formulary review is in its life cycle.
    enum SeasonalFormularyReviewStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A seasonal formulary review as the formulary team keeps it.
    final class SeasonalFormularyReview {
        var code: String
        var title: String
        var name: String
        var retries: Int
        var label: String
        var budget: Double
        var bed: String
        var approved: Bool
        var version: Int
        var sequence: Int
        var procedureCode: String
        var status: SeasonalFormularyReviewStatus

        init(code: String, title: String, name: String, retries: Int, label: String, budget: Double, bed: String, approved: Bool, version: Int, sequence: Int, procedureCode: String, status: SeasonalFormularyReviewStatus) {
            self.code = code
            self.title = title
            self.name = name
            self.retries = retries
            self.label = label
            self.budget = budget
            self.bed = bed
            self.approved = approved
            self.version = version
            self.sequence = sequence
            self.procedureCode = procedureCode
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

        func canMoveTo(_ next: SeasonalFormularyReviewStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == SeasonalFormularyReviewStatus.revoked || next == SeasonalFormularyReviewStatus.expired
            case .revoked:
                return next == SeasonalFormularyReviewStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalFormularyReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal formulary review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\("seasonal formulary review") \(code)"
        }

        func netLoad() -> Double {
            return ((Double(version) - Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalFormularyReview {
            return SeasonalFormularyReview(
                code: code,
                title: title,
                name: name,
                retries: retries,
                label: label,
                budget: budget,
                bed: bed,
                approved: approved,
                version: version,
                sequence: sequence,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a seasonal formulary review in status requested.
    static func newSeasonalFormularyReview(_ code: String, title: String) -> SeasonalFormularyReview {
        return SeasonalFormularyReview(
            code: code,
            title: title,
            name: "",
            retries: 0,
            label: "",
            budget: 0.0,
            bed: "",
            approved: false,
            version: 0,
            sequence: 0,
            procedureCode: "",
            status: SeasonalFormularyReviewStatus.requested
        )
    }
}
