import AcmePlatform
import Foundation

extension Staffing {
    /// Where a credential quota is in its life cycle.
    enum CredentialQuotaStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One credential quota, with what the planners need to act on it.
    final class CredentialQuota {
        var code: String
        var title: String
        var score: Double
        var visitMinutes: Int
        var capacity: Int
        var name: String
        var archived: Bool
        var margin: Double
        var cost: Double
        var facility: String
        var amount: Double
        var status: CredentialQuotaStatus

        init(code: String, title: String, score: Double, visitMinutes: Int, capacity: Int, name: String, archived: Bool, margin: Double, cost: Double, facility: String, amount: Double, status: CredentialQuotaStatus) {
            self.code = code
            self.title = title
            self.score = score
            self.visitMinutes = visitMinutes
            self.capacity = capacity
            self.name = name
            self.archived = archived
            self.margin = margin
            self.cost = cost
            self.facility = facility
            self.amount = amount
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

        func canMoveTo(_ next: CredentialQuotaStatus) -> Bool {
            switch status {
            case .planned:
                return next == CredentialQuotaStatus.cancelled
            case .scheduled:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == CredentialQuotaStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CredentialQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("credential quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("credential quota") \(code)"
        }

        func projectedLoad() -> Double {
            return ((amount - cost) * 100).rounded() / 100
        }

        func copyValue() -> CredentialQuota {
            return CredentialQuota(
                code: code,
                title: title,
                score: score,
                visitMinutes: visitMinutes,
                capacity: capacity,
                name: name,
                archived: archived,
                margin: margin,
                cost: cost,
                facility: facility,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a credential quota in status planned.
    static func newCredentialQuota(_ code: String, title: String) -> CredentialQuota {
        return CredentialQuota(
            code: code,
            title: title,
            score: 0.0,
            visitMinutes: 0,
            capacity: 0,
            name: "",
            archived: false,
            margin: 0.0,
            cost: 0.0,
            facility: "",
            amount: 0.0,
            status: CredentialQuotaStatus.planned
        )
    }
}
