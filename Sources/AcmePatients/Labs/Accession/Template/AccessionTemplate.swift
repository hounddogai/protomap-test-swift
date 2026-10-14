import AcmePlatform
import Foundation

extension Labs {
    /// Where a accession template is in its life cycle.
    enum AccessionTemplateStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A accession template as the accession team keeps it.
    final class AccessionTemplate {
        var code: String
        var title: String
        var active: Bool
        var score: Double
        var updatedAt: Int
        var limit: Int
        var durationMinutes: Int
        var contactEmail: String
        var priority: Int
        var minimum: Double
        var cost: Double
        var status: AccessionTemplateStatus

        init(code: String, title: String, active: Bool, score: Double, updatedAt: Int, limit: Int, durationMinutes: Int, contactEmail: String, priority: Int, minimum: Double, cost: Double, status: AccessionTemplateStatus) {
            self.code = code
            self.title = title
            self.active = active
            self.score = score
            self.updatedAt = updatedAt
            self.limit = limit
            self.durationMinutes = durationMinutes
            self.contactEmail = contactEmail
            self.priority = priority
            self.minimum = minimum
            self.cost = cost
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AccessionTemplateStatus) -> Bool {
            switch status {
            case .idle:
                return next == AccessionTemplateStatus.warming
            case .warming:
                return next == AccessionTemplateStatus.ready || next == AccessionTemplateStatus.stopped
            case .ready:
                return next == AccessionTemplateStatus.draining || next == AccessionTemplateStatus.stopped
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: AccessionTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("accession template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func weightedTotal() -> Double {
            return (Double(priority) * minimum * 100).rounded() / 100
        }

        func copyValue() -> AccessionTemplate {
            return AccessionTemplate(
                code: code,
                title: title,
                active: active,
                score: score,
                updatedAt: updatedAt,
                limit: limit,
                durationMinutes: durationMinutes,
                contactEmail: contactEmail,
                priority: priority,
                minimum: minimum,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a accession template in status idle.
    static func newAccessionTemplate(_ code: String, title: String) -> AccessionTemplate {
        return AccessionTemplate(
            code: code,
            title: title,
            active: false,
            score: 0.0,
            updatedAt: 0,
            limit: 0,
            durationMinutes: 0,
            contactEmail: "",
            priority: 0,
            minimum: 0.0,
            cost: 0.0,
            status: AccessionTemplateStatus.idle
        )
    }
}
