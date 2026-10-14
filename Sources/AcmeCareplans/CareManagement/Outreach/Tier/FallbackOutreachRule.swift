import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a fallback outreach rule is in its life cycle.
    enum FallbackOutreachRuleStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A fallback outreach rule. Its code is unique within a tenant.
    final class FallbackOutreachRule {
        var code: String
        var label: String
        var archived: Bool
        var expiresAt: Int
        var amount: Double
        var rate: Double
        var approved: Bool
        var endsAt: Int
        var limit: Int
        var country: String
        var status: FallbackOutreachRuleStatus

        init(code: String, label: String, archived: Bool, expiresAt: Int, amount: Double, rate: Double, approved: Bool, endsAt: Int, limit: Int, country: String, status: FallbackOutreachRuleStatus) {
            self.code = code
            self.label = label
            self.archived = archived
            self.expiresAt = expiresAt
            self.amount = amount
            self.rate = rate
            self.approved = approved
            self.endsAt = endsAt
            self.limit = limit
            self.country = country
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

        func canMoveTo(_ next: FallbackOutreachRuleStatus) -> Bool {
            switch status {
            case .planned:
                return next == FallbackOutreachRuleStatus.inProgress || next == FallbackOutreachRuleStatus.completed
            case .scheduled:
                return next == FallbackOutreachRuleStatus.inProgress
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == FallbackOutreachRuleStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackOutreachRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback outreach rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func projectedTotal() -> Double {
            return ((Double(expiresAt) + amount) * 100).rounded() / 100
        }

        func copyValue() -> FallbackOutreachRule {
            return FallbackOutreachRule(
                code: code,
                label: label,
                archived: archived,
                expiresAt: expiresAt,
                amount: amount,
                rate: rate,
                approved: approved,
                endsAt: endsAt,
                limit: limit,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a fallback outreach rule in status planned.
    static func newFallbackOutreachRule(_ code: String, label: String) -> FallbackOutreachRule {
        return FallbackOutreachRule(
            code: code,
            label: label,
            archived: false,
            expiresAt: 0,
            amount: 0.0,
            rate: 0.0,
            approved: false,
            endsAt: 0,
            limit: 0,
            country: "",
            status: FallbackOutreachRuleStatus.planned
        )
    }
}
