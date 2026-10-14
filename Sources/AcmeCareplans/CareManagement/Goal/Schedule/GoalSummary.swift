import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a goal summary is in its life cycle.
    enum GoalSummaryStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a goal summary and its current status.
    final class GoalSummary {
        var code: String
        var title: String
        var capacity: Int
        var contactEmail: String
        var minimum: Double
        var country: String
        var attempts: Int
        var payer: String
        var endsAt: Int
        var status: GoalSummaryStatus

        init(code: String, title: String, capacity: Int, contactEmail: String, minimum: Double, country: String, attempts: Int, payer: String, endsAt: Int, status: GoalSummaryStatus) {
            self.code = code
            self.title = title
            self.capacity = capacity
            self.contactEmail = contactEmail
            self.minimum = minimum
            self.country = country
            self.attempts = attempts
            self.payer = payer
            self.endsAt = endsAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: GoalSummaryStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == GoalSummaryStatus.retired
            case .published:
                return next == GoalSummaryStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GoalSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("goal summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func weightedValue() -> Double {
            return ((Double(attempts) + Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> GoalSummary {
            return GoalSummary(
                code: code,
                title: title,
                capacity: capacity,
                contactEmail: contactEmail,
                minimum: minimum,
                country: country,
                attempts: attempts,
                payer: payer,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a goal summary in status created.
    static func newGoalSummary(_ code: String, title: String) -> GoalSummary {
        return GoalSummary(
            code: code,
            title: title,
            capacity: 0,
            contactEmail: "",
            minimum: 0.0,
            country: "",
            attempts: 0,
            payer: "",
            endsAt: 0,
            status: GoalSummaryStatus.created
        )
    }
}
