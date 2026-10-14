import AcmePlatform
import Foundation

extension Labs {
    /// Where a legacy reference range profile is in its life cycle.
    enum LegacyReferenceRangeProfileStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a legacy reference range profile and its current status.
    final class LegacyReferenceRangeProfile {
        var code: String
        var label: String
        var budget: Double
        var summary: String
        var retries: Int
        var status: LegacyReferenceRangeProfileStatus

        init(code: String, label: String, budget: Double, summary: String, retries: Int, status: LegacyReferenceRangeProfileStatus) {
            self.code = code
            self.label = label
            self.budget = budget
            self.summary = summary
            self.retries = retries
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

        func canMoveTo(_ next: LegacyReferenceRangeProfileStatus) -> Bool {
            switch status {
            case .`open`:
                return next == LegacyReferenceRangeProfileStatus.resolved || next == LegacyReferenceRangeProfileStatus.reopened
            case .inReview:
                return next == LegacyReferenceRangeProfileStatus.reopened
            case .resolved:
                return next == LegacyReferenceRangeProfileStatus.archived
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

        func moveTo(_ next: LegacyReferenceRangeProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy reference range profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("legacy reference range profile") \(code)"
        }

        func projectedExposure() -> Double {
            return ((budget - Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> LegacyReferenceRangeProfile {
            return LegacyReferenceRangeProfile(
                code: code,
                label: label,
                budget: budget,
                summary: summary,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a legacy reference range profile in status open.
    static func newLegacyReferenceRangeProfile(_ code: String, label: String) -> LegacyReferenceRangeProfile {
        return LegacyReferenceRangeProfile(
            code: code,
            label: label,
            budget: 0.0,
            summary: "",
            retries: 0,
            status: LegacyReferenceRangeProfileStatus.`open`
        )
    }
}
