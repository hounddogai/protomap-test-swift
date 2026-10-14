import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a statement review is in its life cycle.
    enum StatementReviewStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a statement review and its current status.
    final class StatementReview {
        var code: String
        var name: String
        var country: String
        var ward: String
        var title: String
        var score: Double
        var minimum: Double
        var startsAt: Int
        var priority: Int
        var archived: Bool
        var status: StatementReviewStatus

        init(code: String, name: String, country: String, ward: String, title: String, score: Double, minimum: Double, startsAt: Int, priority: Int, archived: Bool, status: StatementReviewStatus) {
            self.code = code
            self.name = name
            self.country = country
            self.ward = ward
            self.title = title
            self.score = score
            self.minimum = minimum
            self.startsAt = startsAt
            self.priority = priority
            self.archived = archived
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

        func canMoveTo(_ next: StatementReviewStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == StatementReviewStatus.published || next == StatementReviewStatus.retired
            case .published:
                return next == StatementReviewStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StatementReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("statement review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func adjustedTotal() -> Double {
            return ((score + Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> StatementReview {
            return StatementReview(
                code: code,
                name: name,
                country: country,
                ward: ward,
                title: title,
                score: score,
                minimum: minimum,
                startsAt: startsAt,
                priority: priority,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a statement review in status created.
    static func newStatementReview(_ code: String, name: String) -> StatementReview {
        return StatementReview(
            code: code,
            name: name,
            country: "",
            ward: "",
            title: "",
            score: 0.0,
            minimum: 0.0,
            startsAt: 0,
            priority: 0,
            archived: false,
            status: StatementReviewStatus.created
        )
    }
}
