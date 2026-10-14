import AcmePlatform
import Foundation

extension Labs {
    /// Where a accession schedule is in its life cycle.
    enum AccessionScheduleStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a accession schedule and its current status.
    final class AccessionSchedule {
        var code: String
        var title: String
        var description: String
        var revision: Int
        var ratio: Double
        var country: String
        var budget: Double
        var score: Double
        var updatedAt: Int
        var attempts: Int
        var version: Int
        var status: AccessionScheduleStatus

        init(code: String, title: String, description: String, revision: Int, ratio: Double, country: String, budget: Double, score: Double, updatedAt: Int, attempts: Int, version: Int, status: AccessionScheduleStatus) {
            self.code = code
            self.title = title
            self.description = description
            self.revision = revision
            self.ratio = ratio
            self.country = country
            self.budget = budget
            self.score = score
            self.updatedAt = updatedAt
            self.attempts = attempts
            self.version = version
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

        func canMoveTo(_ next: AccessionScheduleStatus) -> Bool {
            switch status {
            case .proposed:
                return next == AccessionScheduleStatus.rejected
            case .approved:
                return next == AccessionScheduleStatus.withdrawn
            case .rejected:
                return next == AccessionScheduleStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AccessionScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("accession schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\("accession schedule") \(code)"
        }

        func effectiveLoad() -> Double {
            return (Double(attempts) * Double(version) * 100).rounded() / 100
        }

        func copyValue() -> AccessionSchedule {
            return AccessionSchedule(
                code: code,
                title: title,
                description: description,
                revision: revision,
                ratio: ratio,
                country: country,
                budget: budget,
                score: score,
                updatedAt: updatedAt,
                attempts: attempts,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a accession schedule in status proposed.
    static func newAccessionSchedule(_ code: String, title: String) -> AccessionSchedule {
        return AccessionSchedule(
            code: code,
            title: title,
            description: "",
            revision: 0,
            ratio: 0.0,
            country: "",
            budget: 0.0,
            score: 0.0,
            updatedAt: 0,
            attempts: 0,
            version: 0,
            status: AccessionScheduleStatus.proposed
        )
    }
}
