import AcmePlatform
import Foundation

extension Referrals {
    /// Where a capped network draft is in its life cycle.
    enum CappedNetworkDraftStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A capped network draft as the network team keeps it.
    final class CappedNetworkDraft {
        var code: String
        var label: String
        var reviewer: String
        var patientRef: String
        var summary: String
        var budget: Double
        var status: CappedNetworkDraftStatus

        init(code: String, label: String, reviewer: String, patientRef: String, summary: String, budget: Double, status: CappedNetworkDraftStatus) {
            self.code = code
            self.label = label
            self.reviewer = reviewer
            self.patientRef = patientRef
            self.summary = summary
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

        func canMoveTo(_ next: CappedNetworkDraftStatus) -> Bool {
            switch status {
            case .`open`:
                return next == CappedNetworkDraftStatus.reopened
            case .inReview:
                return next == CappedNetworkDraftStatus.resolved || next == CappedNetworkDraftStatus.reopened
            case .resolved:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: CappedNetworkDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped network draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("capped network draft") \(code)"
        }

        func measuredValue() -> Double {
            return budget
        }

        func copyValue() -> CappedNetworkDraft {
            return CappedNetworkDraft(
                code: code,
                label: label,
                reviewer: reviewer,
                patientRef: patientRef,
                summary: summary,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a capped network draft in status open.
    static func newCappedNetworkDraft(_ code: String, label: String) -> CappedNetworkDraft {
        return CappedNetworkDraft(
            code: code,
            label: label,
            reviewer: "",
            patientRef: "",
            summary: "",
            budget: 0.0,
            status: CappedNetworkDraftStatus.`open`
        )
    }
}
