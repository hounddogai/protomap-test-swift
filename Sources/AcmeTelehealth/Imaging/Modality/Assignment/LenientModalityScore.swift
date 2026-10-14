import AcmePlatform
import Foundation

extension Imaging {
    /// Where a lenient modality score is in its life cycle.
    enum LenientModalityScoreStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A lenient modality score. Its code is unique within a tenant.
    final class LenientModalityScore {
        var code: String
        var title: String
        var patientRef: String
        var priority: Int
        var contactEmail: String
        var currency: String
        var allergy: String
        var externalRef: String
        var pinned: Bool
        var expiresAt: Int
        var limit: Int
        var status: LenientModalityScoreStatus

        init(code: String, title: String, patientRef: String, priority: Int, contactEmail: String, currency: String, allergy: String, externalRef: String, pinned: Bool, expiresAt: Int, limit: Int, status: LenientModalityScoreStatus) {
            self.code = code
            self.title = title
            self.patientRef = patientRef
            self.priority = priority
            self.contactEmail = contactEmail
            self.currency = currency
            self.allergy = allergy
            self.externalRef = externalRef
            self.pinned = pinned
            self.expiresAt = expiresAt
            self.limit = limit
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LenientModalityScoreStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == LenientModalityScoreStatus.inProgress || next == LenientModalityScoreStatus.completed
            case .inProgress:
                return next == LenientModalityScoreStatus.cancelled
            case .completed:
                return next == LenientModalityScoreStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientModalityScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient modality score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("lenient modality score") \(code)"
        }

        func projectedExposure() -> Double {
            return ((Double(priority) + Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> LenientModalityScore {
            return LenientModalityScore(
                code: code,
                title: title,
                patientRef: patientRef,
                priority: priority,
                contactEmail: contactEmail,
                currency: currency,
                allergy: allergy,
                externalRef: externalRef,
                pinned: pinned,
                expiresAt: expiresAt,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a lenient modality score in status planned.
    static func newLenientModalityScore(_ code: String, title: String) -> LenientModalityScore {
        return LenientModalityScore(
            code: code,
            title: title,
            patientRef: "",
            priority: 0,
            contactEmail: "",
            currency: "",
            allergy: "",
            externalRef: "",
            pinned: false,
            expiresAt: 0,
            limit: 0,
            status: LenientModalityScoreStatus.planned
        )
    }
}
