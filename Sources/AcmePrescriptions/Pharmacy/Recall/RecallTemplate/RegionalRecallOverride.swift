import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a regional recall override is in its life cycle.
    enum RegionalRecallOverrideStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A regional recall override. Its code is unique within a tenant.
    final class RegionalRecallOverride {
        var code: String
        var label: String
        var ceiling: Double
        var budget: Double
        var tags: [String]
        var currency: String
        var channel: String
        var bed: String
        var pinned: Bool
        var procedureCode: String
        var status: RegionalRecallOverrideStatus

        init(code: String, label: String, ceiling: Double, budget: Double, tags: [String], currency: String, channel: String, bed: String, pinned: Bool, procedureCode: String, status: RegionalRecallOverrideStatus) {
            self.code = code
            self.label = label
            self.ceiling = ceiling
            self.budget = budget
            self.tags = tags
            self.currency = currency
            self.channel = channel
            self.bed = bed
            self.pinned = pinned
            self.procedureCode = procedureCode
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

        func canMoveTo(_ next: RegionalRecallOverrideStatus) -> Bool {
            switch status {
            case .`open`:
                return next == RegionalRecallOverrideStatus.inReview || next == RegionalRecallOverrideStatus.reopened
            case .inReview:
                return next == RegionalRecallOverrideStatus.reopened || next == RegionalRecallOverrideStatus.archived
            case .resolved:
                return next == RegionalRecallOverrideStatus.reopened || next == RegionalRecallOverrideStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: RegionalRecallOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional recall override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedLoad() -> Double {
            return (budget * ceiling * 100).rounded() / 100
        }

        func copyValue() -> RegionalRecallOverride {
            return RegionalRecallOverride(
                code: code,
                label: label,
                ceiling: ceiling,
                budget: budget,
                tags: tags,
                currency: currency,
                channel: channel,
                bed: bed,
                pinned: pinned,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a regional recall override in status open.
    static func newRegionalRecallOverride(_ code: String, label: String) -> RegionalRecallOverride {
        return RegionalRecallOverride(
            code: code,
            label: label,
            ceiling: 0.0,
            budget: 0.0,
            tags: [],
            currency: "",
            channel: "",
            bed: "",
            pinned: false,
            procedureCode: "",
            status: RegionalRecallOverrideStatus.`open`
        )
    }
}
