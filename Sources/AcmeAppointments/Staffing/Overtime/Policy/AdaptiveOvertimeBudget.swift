import AcmePlatform
import Foundation

extension Staffing {
    /// Where a adaptive overtime budget is in its life cycle.
    enum AdaptiveOvertimeBudgetStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a adaptive overtime budget and its current status.
    final class AdaptiveOvertimeBudget {
        var code: String
        var label: String
        var createdAt: Int
        var clinicianID: String
        var notes: String
        var reviewer: String
        var threshold: Double
        var status: AdaptiveOvertimeBudgetStatus

        init(code: String, label: String, createdAt: Int, clinicianID: String, notes: String, reviewer: String, threshold: Double, status: AdaptiveOvertimeBudgetStatus) {
            self.code = code
            self.label = label
            self.createdAt = createdAt
            self.clinicianID = clinicianID
            self.notes = notes
            self.reviewer = reviewer
            self.threshold = threshold
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

        func canMoveTo(_ next: AdaptiveOvertimeBudgetStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == AdaptiveOvertimeBudgetStatus.archived
            case .resolved:
                switch next {
                case .archived:
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

        func moveTo(_ next: AdaptiveOvertimeBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive overtime budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func effectiveTotal() -> Double {
            return ((threshold + Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveOvertimeBudget {
            return AdaptiveOvertimeBudget(
                code: code,
                label: label,
                createdAt: createdAt,
                clinicianID: clinicianID,
                notes: notes,
                reviewer: reviewer,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a adaptive overtime budget in status open.
    static func newAdaptiveOvertimeBudget(_ code: String, label: String) -> AdaptiveOvertimeBudget {
        return AdaptiveOvertimeBudget(
            code: code,
            label: label,
            createdAt: 0,
            clinicianID: "",
            notes: "",
            reviewer: "",
            threshold: 0.0,
            status: AdaptiveOvertimeBudgetStatus.`open`
        )
    }
}
