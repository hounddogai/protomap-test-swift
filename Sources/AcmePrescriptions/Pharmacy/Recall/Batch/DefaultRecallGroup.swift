import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a default recall group is in its life cycle.
    enum DefaultRecallGroupStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One default recall group, with what the planners need to act on it.
    final class DefaultRecallGroup {
        var code: String
        var title: String
        var expiresAt: Int
        var attempts: Int
        var locale: String
        var ownerID: String
        var sequence: Int
        var endsAt: Int
        var budget: Double
        var segment: String
        var patientRef: String
        var status: DefaultRecallGroupStatus

        init(code: String, title: String, expiresAt: Int, attempts: Int, locale: String, ownerID: String, sequence: Int, endsAt: Int, budget: Double, segment: String, patientRef: String, status: DefaultRecallGroupStatus) {
            self.code = code
            self.title = title
            self.expiresAt = expiresAt
            self.attempts = attempts
            self.locale = locale
            self.ownerID = ownerID
            self.sequence = sequence
            self.endsAt = endsAt
            self.budget = budget
            self.segment = segment
            self.patientRef = patientRef
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

        func canMoveTo(_ next: DefaultRecallGroupStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == DefaultRecallGroupStatus.reopened
            case .resolved:
                return next == DefaultRecallGroupStatus.reopened || next == DefaultRecallGroupStatus.archived
            case .reopened:
                return next == DefaultRecallGroupStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultRecallGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default recall group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("default recall group") \(code)"
        }

        func weightedValue() -> Double {
            return ((Double(endsAt) + Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> DefaultRecallGroup {
            return DefaultRecallGroup(
                code: code,
                title: title,
                expiresAt: expiresAt,
                attempts: attempts,
                locale: locale,
                ownerID: ownerID,
                sequence: sequence,
                endsAt: endsAt,
                budget: budget,
                segment: segment,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a default recall group in status open.
    static func newDefaultRecallGroup(_ code: String, title: String) -> DefaultRecallGroup {
        return DefaultRecallGroup(
            code: code,
            title: title,
            expiresAt: 0,
            attempts: 0,
            locale: "",
            ownerID: "",
            sequence: 0,
            endsAt: 0,
            budget: 0.0,
            segment: "",
            patientRef: "",
            status: DefaultRecallGroupStatus.`open`
        )
    }
}
