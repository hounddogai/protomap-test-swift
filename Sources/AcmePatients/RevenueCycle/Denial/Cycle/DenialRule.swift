import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a denial rule is in its life cycle.
    enum DenialRuleStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a denial rule and its current status.
    final class DenialRule {
        var code: String
        var name: String
        var approved: Bool
        var limit: Int
        var endsAt: Int
        var expiresAt: Int
        var active: Bool
        var facility: String
        var archived: Bool
        var discount: Double
        var procedureCode: String
        var status: DenialRuleStatus

        init(code: String, name: String, approved: Bool, limit: Int, endsAt: Int, expiresAt: Int, active: Bool, facility: String, archived: Bool, discount: Double, procedureCode: String, status: DenialRuleStatus) {
            self.code = code
            self.name = name
            self.approved = approved
            self.limit = limit
            self.endsAt = endsAt
            self.expiresAt = expiresAt
            self.active = active
            self.facility = facility
            self.archived = archived
            self.discount = discount
            self.procedureCode = procedureCode
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

        func canMoveTo(_ next: DenialRuleStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .cancelled:
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
                return next == DenialRuleStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DenialRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("denial rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("denial rule") \(code)"
        }

        func netVolume() -> Double {
            return ((Double(expiresAt) - discount) * 100).rounded() / 100
        }

        func copyValue() -> DenialRule {
            return DenialRule(
                code: code,
                name: name,
                approved: approved,
                limit: limit,
                endsAt: endsAt,
                expiresAt: expiresAt,
                active: active,
                facility: facility,
                archived: archived,
                discount: discount,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a denial rule in status planned.
    static func newDenialRule(_ code: String, name: String) -> DenialRule {
        return DenialRule(
            code: code,
            name: name,
            approved: false,
            limit: 0,
            endsAt: 0,
            expiresAt: 0,
            active: false,
            facility: "",
            archived: false,
            discount: 0.0,
            procedureCode: "",
            status: DenialRuleStatus.planned
        )
    }
}
