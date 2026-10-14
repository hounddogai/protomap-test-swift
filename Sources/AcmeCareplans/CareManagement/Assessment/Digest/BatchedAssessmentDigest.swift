import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a batched assessment digest is in its life cycle.
    enum BatchedAssessmentDigestStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A batched assessment digest as the assessment team keeps it.
    final class BatchedAssessmentDigest {
        var code: String
        var title: String
        var visitMinutes: Int
        var contactEmail: String
        var discount: Double
        var startsAt: Int
        var status: BatchedAssessmentDigestStatus

        init(code: String, title: String, visitMinutes: Int, contactEmail: String, discount: Double, startsAt: Int, status: BatchedAssessmentDigestStatus) {
            self.code = code
            self.title = title
            self.visitMinutes = visitMinutes
            self.contactEmail = contactEmail
            self.discount = discount
            self.startsAt = startsAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: BatchedAssessmentDigestStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == BatchedAssessmentDigestStatus.rejected || next == BatchedAssessmentDigestStatus.withdrawn
            case .rejected:
                return next == BatchedAssessmentDigestStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedAssessmentDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched assessment digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func adjustedValue() -> Double {
            return ((discount + Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> BatchedAssessmentDigest {
            return BatchedAssessmentDigest(
                code: code,
                title: title,
                visitMinutes: visitMinutes,
                contactEmail: contactEmail,
                discount: discount,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a batched assessment digest in status proposed.
    static func newBatchedAssessmentDigest(_ code: String, title: String) -> BatchedAssessmentDigest {
        return BatchedAssessmentDigest(
            code: code,
            title: title,
            visitMinutes: 0,
            contactEmail: "",
            discount: 0.0,
            startsAt: 0,
            status: BatchedAssessmentDigestStatus.proposed
        )
    }
}
