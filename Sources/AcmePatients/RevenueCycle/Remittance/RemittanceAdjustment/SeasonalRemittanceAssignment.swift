import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a seasonal remittance assignment is in its life cycle.
    enum SeasonalRemittanceAssignmentStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A seasonal remittance assignment. Its code is unique within a tenant.
    final class SeasonalRemittanceAssignment {
        var code: String
        var label: String
        var tags: [String]
        var segment: String
        var budget: Double
        var status: SeasonalRemittanceAssignmentStatus

        init(code: String, label: String, tags: [String], segment: String, budget: Double, status: SeasonalRemittanceAssignmentStatus) {
            self.code = code
            self.label = label
            self.tags = tags
            self.segment = segment
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

        func canMoveTo(_ next: SeasonalRemittanceAssignmentStatus) -> Bool {
            switch status {
            case .`open`:
                return next == SeasonalRemittanceAssignmentStatus.archived
            case .inReview:
                return next == SeasonalRemittanceAssignmentStatus.reopened
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == SeasonalRemittanceAssignmentStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalRemittanceAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal remittance assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("seasonal remittance assignment") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func measuredValue() -> Double {
            return budget
        }

        func copyValue() -> SeasonalRemittanceAssignment {
            return SeasonalRemittanceAssignment(
                code: code,
                label: label,
                tags: tags,
                segment: segment,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a seasonal remittance assignment in status open.
    static func newSeasonalRemittanceAssignment(_ code: String, label: String) -> SeasonalRemittanceAssignment {
        return SeasonalRemittanceAssignment(
            code: code,
            label: label,
            tags: [],
            segment: "",
            budget: 0.0,
            status: SeasonalRemittanceAssignmentStatus.`open`
        )
    }
}
