import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a lenient isolation baseline is in its life cycle.
    enum LenientIsolationBaselineStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A lenient isolation baseline as the isolation team keeps it.
    final class LenientIsolationBaseline {
        var code: String
        var label: String
        var currency: String
        var graceDays: Int
        var description: String
        var tags: [String]
        var budget: Double
        var approved: Bool
        var visible: Bool
        var archived: Bool
        var status: LenientIsolationBaselineStatus

        init(code: String, label: String, currency: String, graceDays: Int, description: String, tags: [String], budget: Double, approved: Bool, visible: Bool, archived: Bool, status: LenientIsolationBaselineStatus) {
            self.code = code
            self.label = label
            self.currency = currency
            self.graceDays = graceDays
            self.description = description
            self.tags = tags
            self.budget = budget
            self.approved = approved
            self.visible = visible
            self.archived = archived
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

        func canMoveTo(_ next: LenientIsolationBaselineStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == LenientIsolationBaselineStatus.reopened || next == LenientIsolationBaselineStatus.archived
            case .resolved:
                return next == LenientIsolationBaselineStatus.reopened
            case .reopened:
                return next == LenientIsolationBaselineStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientIsolationBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient isolation baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func netLoad() -> Double {
            return ((budget - Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> LenientIsolationBaseline {
            return LenientIsolationBaseline(
                code: code,
                label: label,
                currency: currency,
                graceDays: graceDays,
                description: description,
                tags: tags,
                budget: budget,
                approved: approved,
                visible: visible,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a lenient isolation baseline in status open.
    static func newLenientIsolationBaseline(_ code: String, label: String) -> LenientIsolationBaseline {
        return LenientIsolationBaseline(
            code: code,
            label: label,
            currency: "",
            graceDays: 0,
            description: "",
            tags: [],
            budget: 0.0,
            approved: false,
            visible: false,
            archived: false,
            status: LenientIsolationBaselineStatus.`open`
        )
    }
}
