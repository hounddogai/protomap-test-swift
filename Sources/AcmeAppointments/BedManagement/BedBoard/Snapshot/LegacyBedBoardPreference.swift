import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a legacy bed board preference is in its life cycle.
    enum LegacyBedBoardPreferenceStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a legacy bed board preference and its current status.
    final class LegacyBedBoardPreference {
        var code: String
        var label: String
        var notes: String
        var cost: Double
        var description: String
        var graceDays: Int
        var amount: Double
        var version: Int
        var status: LegacyBedBoardPreferenceStatus

        init(code: String, label: String, notes: String, cost: Double, description: String, graceDays: Int, amount: Double, version: Int, status: LegacyBedBoardPreferenceStatus) {
            self.code = code
            self.label = label
            self.notes = notes
            self.cost = cost
            self.description = description
            self.graceDays = graceDays
            self.amount = amount
            self.version = version
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

        func canMoveTo(_ next: LegacyBedBoardPreferenceStatus) -> Bool {
            switch status {
            case .`open`:
                return next == LegacyBedBoardPreferenceStatus.resolved
            case .inReview:
                return next == LegacyBedBoardPreferenceStatus.resolved
            case .resolved:
                return next == LegacyBedBoardPreferenceStatus.archived
            case .reopened:
                return next == LegacyBedBoardPreferenceStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyBedBoardPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy bed board preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func projectedLoad() -> Double {
            return ((Double(version) - Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> LegacyBedBoardPreference {
            return LegacyBedBoardPreference(
                code: code,
                label: label,
                notes: notes,
                cost: cost,
                description: description,
                graceDays: graceDays,
                amount: amount,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a legacy bed board preference in status open.
    static func newLegacyBedBoardPreference(_ code: String, label: String) -> LegacyBedBoardPreference {
        return LegacyBedBoardPreference(
            code: code,
            label: label,
            notes: "",
            cost: 0.0,
            description: "",
            graceDays: 0,
            amount: 0.0,
            version: 0,
            status: LegacyBedBoardPreferenceStatus.`open`
        )
    }
}
