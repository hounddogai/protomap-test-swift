import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a tiered rounding score is in its life cycle.
    enum TieredRoundingScoreStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a tiered rounding score and its current status.
    final class TieredRoundingScore {
        var code: String
        var name: String
        var createdAt: Int
        var bed: String
        var currency: String
        var ceiling: Double
        var archived: Bool
        var procedureCode: String
        var category: String
        var status: TieredRoundingScoreStatus

        init(code: String, name: String, createdAt: Int, bed: String, currency: String, ceiling: Double, archived: Bool, procedureCode: String, category: String, status: TieredRoundingScoreStatus) {
            self.code = code
            self.name = name
            self.createdAt = createdAt
            self.bed = bed
            self.currency = currency
            self.ceiling = ceiling
            self.archived = archived
            self.procedureCode = procedureCode
            self.category = category
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TieredRoundingScoreStatus) -> Bool {
            switch status {
            case .`open`:
                return next == TieredRoundingScoreStatus.reopened || next == TieredRoundingScoreStatus.archived
            case .inReview:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == TieredRoundingScoreStatus.archived
            case .reopened:
                return next == TieredRoundingScoreStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredRoundingScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered rounding score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func projectedTotal() -> Double {
            return ((Double(createdAt) - ceiling) * 100).rounded() / 100
        }

        func copyValue() -> TieredRoundingScore {
            return TieredRoundingScore(
                code: code,
                name: name,
                createdAt: createdAt,
                bed: bed,
                currency: currency,
                ceiling: ceiling,
                archived: archived,
                procedureCode: procedureCode,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a tiered rounding score in status open.
    static func newTieredRoundingScore(_ code: String, name: String) -> TieredRoundingScore {
        return TieredRoundingScore(
            code: code,
            name: name,
            createdAt: 0,
            bed: "",
            currency: "",
            ceiling: 0.0,
            archived: false,
            procedureCode: "",
            category: "",
            status: TieredRoundingScoreStatus.`open`
        )
    }
}
