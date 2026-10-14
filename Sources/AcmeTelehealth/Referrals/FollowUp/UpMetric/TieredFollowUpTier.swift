import AcmePlatform
import Foundation

extension Referrals {
    /// Where a tiered follow up tier is in its life cycle.
    enum TieredFollowUpTierStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A tiered follow up tier as the follow up team keeps it.
    final class TieredFollowUpTier {
        var code: String
        var name: String
        var description: String
        var externalRef: String
        var budget: Double
        var ownerID: String
        var bed: String
        var category: String
        var updatedAt: Int
        var source: String
        var reviewer: String
        var status: TieredFollowUpTierStatus

        init(code: String, name: String, description: String, externalRef: String, budget: Double, ownerID: String, bed: String, category: String, updatedAt: Int, source: String, reviewer: String, status: TieredFollowUpTierStatus) {
            self.code = code
            self.name = name
            self.description = description
            self.externalRef = externalRef
            self.budget = budget
            self.ownerID = ownerID
            self.bed = bed
            self.category = category
            self.updatedAt = updatedAt
            self.source = source
            self.reviewer = reviewer
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

        func canMoveTo(_ next: TieredFollowUpTierStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == TieredFollowUpTierStatus.active || next == TieredFollowUpTierStatus.suspended
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == TieredFollowUpTierStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredFollowUpTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered follow up tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func adjustedLoad() -> Double {
            return ((budget + Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> TieredFollowUpTier {
            return TieredFollowUpTier(
                code: code,
                name: name,
                description: description,
                externalRef: externalRef,
                budget: budget,
                ownerID: ownerID,
                bed: bed,
                category: category,
                updatedAt: updatedAt,
                source: source,
                reviewer: reviewer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a tiered follow up tier in status draft.
    static func newTieredFollowUpTier(_ code: String, name: String) -> TieredFollowUpTier {
        return TieredFollowUpTier(
            code: code,
            name: name,
            description: "",
            externalRef: "",
            budget: 0.0,
            ownerID: "",
            bed: "",
            category: "",
            updatedAt: 0,
            source: "",
            reviewer: "",
            status: TieredFollowUpTierStatus.draft
        )
    }
}
