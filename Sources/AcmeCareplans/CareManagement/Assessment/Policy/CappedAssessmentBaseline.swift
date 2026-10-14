import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a capped assessment baseline is in its life cycle.
    enum CappedAssessmentBaselineStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A capped assessment baseline. Its code is unique within a tenant.
    final class CappedAssessmentBaseline {
        var code: String
        var label: String
        var capacity: Int
        var externalRef: String
        var bed: String
        var reviewer: String
        var copay: Double
        var expiresAt: Int
        var status: CappedAssessmentBaselineStatus

        init(code: String, label: String, capacity: Int, externalRef: String, bed: String, reviewer: String, copay: Double, expiresAt: Int, status: CappedAssessmentBaselineStatus) {
            self.code = code
            self.label = label
            self.capacity = capacity
            self.externalRef = externalRef
            self.bed = bed
            self.reviewer = reviewer
            self.copay = copay
            self.expiresAt = expiresAt
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

        func canMoveTo(_ next: CappedAssessmentBaselineStatus) -> Bool {
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
                return next == CappedAssessmentBaselineStatus.resolved
            case .resolved:
                return next == CappedAssessmentBaselineStatus.reopened || next == CappedAssessmentBaselineStatus.archived
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

        func moveTo(_ next: CappedAssessmentBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped assessment baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func netValue() -> Double {
            return ((copay + Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> CappedAssessmentBaseline {
            return CappedAssessmentBaseline(
                code: code,
                label: label,
                capacity: capacity,
                externalRef: externalRef,
                bed: bed,
                reviewer: reviewer,
                copay: copay,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a capped assessment baseline in status open.
    static func newCappedAssessmentBaseline(_ code: String, label: String) -> CappedAssessmentBaseline {
        return CappedAssessmentBaseline(
            code: code,
            label: label,
            capacity: 0,
            externalRef: "",
            bed: "",
            reviewer: "",
            copay: 0.0,
            expiresAt: 0,
            status: CappedAssessmentBaselineStatus.`open`
        )
    }
}
