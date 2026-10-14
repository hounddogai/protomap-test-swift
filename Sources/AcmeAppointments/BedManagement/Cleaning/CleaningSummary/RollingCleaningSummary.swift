import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a rolling cleaning summary is in its life cycle.
    enum RollingCleaningSummaryStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a rolling cleaning summary and its current status.
    final class RollingCleaningSummary {
        var code: String
        var title: String
        var country: String
        var archived: Bool
        var facility: String
        var reviewer: String
        var unit: String
        var summary: String
        var label: String
        var cost: Double
        var attributes: [String: String]
        var status: RollingCleaningSummaryStatus

        init(code: String, title: String, country: String, archived: Bool, facility: String, reviewer: String, unit: String, summary: String, label: String, cost: Double, attributes: [String: String], status: RollingCleaningSummaryStatus) {
            self.code = code
            self.title = title
            self.country = country
            self.archived = archived
            self.facility = facility
            self.reviewer = reviewer
            self.unit = unit
            self.summary = summary
            self.label = label
            self.cost = cost
            self.attributes = attributes
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

        func canMoveTo(_ next: RollingCleaningSummaryStatus) -> Bool {
            switch status {
            case .created:
                return next == RollingCleaningSummaryStatus.validated || next == RollingCleaningSummaryStatus.published
            case .validated:
                return next == RollingCleaningSummaryStatus.published
            case .published:
                return next == RollingCleaningSummaryStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingCleaningSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling cleaning summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(title)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func measuredValue() -> Double {
            return cost
        }

        func copyValue() -> RollingCleaningSummary {
            return RollingCleaningSummary(
                code: code,
                title: title,
                country: country,
                archived: archived,
                facility: facility,
                reviewer: reviewer,
                unit: unit,
                summary: summary,
                label: label,
                cost: cost,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a rolling cleaning summary in status created.
    static func newRollingCleaningSummary(_ code: String, title: String) -> RollingCleaningSummary {
        return RollingCleaningSummary(
            code: code,
            title: title,
            country: "",
            archived: false,
            facility: "",
            reviewer: "",
            unit: "",
            summary: "",
            label: "",
            cost: 0.0,
            attributes: [:],
            status: RollingCleaningSummaryStatus.created
        )
    }
}
