import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a batched remittance target is in its life cycle.
    enum BatchedRemittanceTargetStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One batched remittance target, with what the planners need to act on it.
    final class BatchedRemittanceTarget {
        var code: String
        var title: String
        var refills: Int
        var ownerID: String
        var patientRef: String
        var graceDays: Int
        var endsAt: Int
        var attempts: Int
        var limit: Int
        var locale: String
        var status: BatchedRemittanceTargetStatus

        init(code: String, title: String, refills: Int, ownerID: String, patientRef: String, graceDays: Int, endsAt: Int, attempts: Int, limit: Int, locale: String, status: BatchedRemittanceTargetStatus) {
            self.code = code
            self.title = title
            self.refills = refills
            self.ownerID = ownerID
            self.patientRef = patientRef
            self.graceDays = graceDays
            self.endsAt = endsAt
            self.attempts = attempts
            self.limit = limit
            self.locale = locale
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

        func canMoveTo(_ next: BatchedRemittanceTargetStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == BatchedRemittanceTargetStatus.archived
            case .resolved:
                return next == BatchedRemittanceTargetStatus.archived
            case .reopened:
                return next == BatchedRemittanceTargetStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedRemittanceTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched remittance target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("batched remittance target") \(code)"
        }

        func netValue() -> Double {
            return ((Double(refills) + Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> BatchedRemittanceTarget {
            return BatchedRemittanceTarget(
                code: code,
                title: title,
                refills: refills,
                ownerID: ownerID,
                patientRef: patientRef,
                graceDays: graceDays,
                endsAt: endsAt,
                attempts: attempts,
                limit: limit,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a batched remittance target in status open.
    static func newBatchedRemittanceTarget(_ code: String, title: String) -> BatchedRemittanceTarget {
        return BatchedRemittanceTarget(
            code: code,
            title: title,
            refills: 0,
            ownerID: "",
            patientRef: "",
            graceDays: 0,
            endsAt: 0,
            attempts: 0,
            limit: 0,
            locale: "",
            status: BatchedRemittanceTargetStatus.`open`
        )
    }
}
