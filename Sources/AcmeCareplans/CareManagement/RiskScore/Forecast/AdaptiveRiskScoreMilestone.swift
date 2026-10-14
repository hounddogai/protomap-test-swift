import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a adaptive risk score milestone is in its life cycle.
    enum AdaptiveRiskScoreMilestoneStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One adaptive risk score milestone, with what the planners need to act on it.
    final class AdaptiveRiskScoreMilestone {
        var code: String
        var title: String
        var tags: [String]
        var ceiling: Double
        var country: String
        var sequence: Int
        var ownerID: String
        var cost: Double
        var summary: String
        var status: AdaptiveRiskScoreMilestoneStatus

        init(code: String, title: String, tags: [String], ceiling: Double, country: String, sequence: Int, ownerID: String, cost: Double, summary: String, status: AdaptiveRiskScoreMilestoneStatus) {
            self.code = code
            self.title = title
            self.tags = tags
            self.ceiling = ceiling
            self.country = country
            self.sequence = sequence
            self.ownerID = ownerID
            self.cost = cost
            self.summary = summary
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AdaptiveRiskScoreMilestoneStatus) -> Bool {
            switch status {
            case .created:
                return next == AdaptiveRiskScoreMilestoneStatus.validated || next == AdaptiveRiskScoreMilestoneStatus.retired
            case .validated:
                return next == AdaptiveRiskScoreMilestoneStatus.published
            case .published:
                return next == AdaptiveRiskScoreMilestoneStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveRiskScoreMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive risk score milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("adaptive risk score milestone") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveValue() -> Double {
            return (cost * ceiling * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveRiskScoreMilestone {
            return AdaptiveRiskScoreMilestone(
                code: code,
                title: title,
                tags: tags,
                ceiling: ceiling,
                country: country,
                sequence: sequence,
                ownerID: ownerID,
                cost: cost,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a adaptive risk score milestone in status created.
    static func newAdaptiveRiskScoreMilestone(_ code: String, title: String) -> AdaptiveRiskScoreMilestone {
        return AdaptiveRiskScoreMilestone(
            code: code,
            title: title,
            tags: [],
            ceiling: 0.0,
            country: "",
            sequence: 0,
            ownerID: "",
            cost: 0.0,
            summary: "",
            status: AdaptiveRiskScoreMilestoneStatus.created
        )
    }
}
