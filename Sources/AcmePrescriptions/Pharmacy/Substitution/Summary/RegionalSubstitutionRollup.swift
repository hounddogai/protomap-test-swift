import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a regional substitution rollup is in its life cycle.
    enum RegionalSubstitutionRollupStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a regional substitution rollup and its current status.
    final class RegionalSubstitutionRollup {
        var code: String
        var title: String
        var ceiling: Double
        var batchSize: Int
        var region: String
        var budget: Double
        var status: RegionalSubstitutionRollupStatus

        init(code: String, title: String, ceiling: Double, batchSize: Int, region: String, budget: Double, status: RegionalSubstitutionRollupStatus) {
            self.code = code
            self.title = title
            self.ceiling = ceiling
            self.batchSize = batchSize
            self.region = region
            self.budget = budget
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

        func canMoveTo(_ next: RegionalSubstitutionRollupStatus) -> Bool {
            switch status {
            case .`open`:
                return next == RegionalSubstitutionRollupStatus.resolved
            case .inReview:
                return next == RegionalSubstitutionRollupStatus.archived
            case .resolved:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == RegionalSubstitutionRollupStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalSubstitutionRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional substitution rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func weightedVolume() -> Double {
            return (ceiling * budget * 100).rounded() / 100
        }

        func copyValue() -> RegionalSubstitutionRollup {
            return RegionalSubstitutionRollup(
                code: code,
                title: title,
                ceiling: ceiling,
                batchSize: batchSize,
                region: region,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a regional substitution rollup in status open.
    static func newRegionalSubstitutionRollup(_ code: String, title: String) -> RegionalSubstitutionRollup {
        return RegionalSubstitutionRollup(
            code: code,
            title: title,
            ceiling: 0.0,
            batchSize: 0,
            region: "",
            budget: 0.0,
            status: RegionalSubstitutionRollupStatus.`open`
        )
    }
}
