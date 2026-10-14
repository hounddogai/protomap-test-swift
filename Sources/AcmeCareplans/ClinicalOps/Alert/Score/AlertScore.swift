import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a alert score is in its life cycle.
    enum AlertScoreStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One alert score, with what the planners need to act on it.
    final class AlertScore {
        var code: String
        var title: String
        var retries: Int
        var category: String
        var capacity: Int
        var country: String
        var patientRef: String
        var budget: Double
        var status: AlertScoreStatus

        init(code: String, title: String, retries: Int, category: String, capacity: Int, country: String, patientRef: String, budget: Double, status: AlertScoreStatus) {
            self.code = code
            self.title = title
            self.retries = retries
            self.category = category
            self.capacity = capacity
            self.country = country
            self.patientRef = patientRef
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

        func canMoveTo(_ next: AlertScoreStatus) -> Bool {
            switch status {
            case .`open`:
                return next == AlertScoreStatus.reopened
            case .inReview:
                return next == AlertScoreStatus.archived
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

        func moveTo(_ next: AlertScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("alert score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func weightedValue() -> Double {
            return (Double(retries) * budget * 100).rounded() / 100
        }

        func copyValue() -> AlertScore {
            return AlertScore(
                code: code,
                title: title,
                retries: retries,
                category: category,
                capacity: capacity,
                country: country,
                patientRef: patientRef,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a alert score in status open.
    static func newAlertScore(_ code: String, title: String) -> AlertScore {
        return AlertScore(
            code: code,
            title: title,
            retries: 0,
            category: "",
            capacity: 0,
            country: "",
            patientRef: "",
            budget: 0.0,
            status: AlertScoreStatus.`open`
        )
    }
}
