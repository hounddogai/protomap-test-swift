import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a batched assessment baseline is in its life cycle.
    enum BatchedAssessmentBaselineStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a batched assessment baseline and its current status.
    final class BatchedAssessmentBaseline {
        var code: String
        var label: String
        var capacity: Int
        var unit: String
        var contactEmail: String
        var retries: Int
        var acuity: Int
        var revision: Int
        var weight: Double
        var expiresAt: Int
        var payer: String
        var status: BatchedAssessmentBaselineStatus

        init(code: String, label: String, capacity: Int, unit: String, contactEmail: String, retries: Int, acuity: Int, revision: Int, weight: Double, expiresAt: Int, payer: String, status: BatchedAssessmentBaselineStatus) {
            self.code = code
            self.label = label
            self.capacity = capacity
            self.unit = unit
            self.contactEmail = contactEmail
            self.retries = retries
            self.acuity = acuity
            self.revision = revision
            self.weight = weight
            self.expiresAt = expiresAt
            self.payer = payer
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

        func canMoveTo(_ next: BatchedAssessmentBaselineStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == BatchedAssessmentBaselineStatus.archived
            case .resolved:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == BatchedAssessmentBaselineStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedAssessmentBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched assessment baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func displayLabel() -> String {
            return "\("batched assessment baseline") \(code)"
        }

        func adjustedTotal() -> Double {
            return ((weight + Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> BatchedAssessmentBaseline {
            return BatchedAssessmentBaseline(
                code: code,
                label: label,
                capacity: capacity,
                unit: unit,
                contactEmail: contactEmail,
                retries: retries,
                acuity: acuity,
                revision: revision,
                weight: weight,
                expiresAt: expiresAt,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a batched assessment baseline in status open.
    static func newBatchedAssessmentBaseline(_ code: String, label: String) -> BatchedAssessmentBaseline {
        return BatchedAssessmentBaseline(
            code: code,
            label: label,
            capacity: 0,
            unit: "",
            contactEmail: "",
            retries: 0,
            acuity: 0,
            revision: 0,
            weight: 0.0,
            expiresAt: 0,
            payer: "",
            status: BatchedAssessmentBaselineStatus.`open`
        )
    }
}
