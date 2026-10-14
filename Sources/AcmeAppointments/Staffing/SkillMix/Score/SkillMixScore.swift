import AcmePlatform
import Foundation

extension Staffing {
    /// Where a skill mix score is in its life cycle.
    enum SkillMixScoreStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A skill mix score. Its code is unique within a tenant.
    final class SkillMixScore {
        var code: String
        var name: String
        var ratio: Double
        var amount: Double
        var contactEmail: String
        var limit: Int
        var durationMinutes: Int
        var expiresAt: Int
        var category: String
        var facility: String
        var ward: String
        var status: SkillMixScoreStatus

        init(code: String, name: String, ratio: Double, amount: Double, contactEmail: String, limit: Int, durationMinutes: Int, expiresAt: Int, category: String, facility: String, ward: String, status: SkillMixScoreStatus) {
            self.code = code
            self.name = name
            self.ratio = ratio
            self.amount = amount
            self.contactEmail = contactEmail
            self.limit = limit
            self.durationMinutes = durationMinutes
            self.expiresAt = expiresAt
            self.category = category
            self.facility = facility
            self.ward = ward
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SkillMixScoreStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: SkillMixScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("skill mix score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func projectedExposure() -> Double {
            return ((amount - ratio) * 100).rounded() / 100
        }

        func copyValue() -> SkillMixScore {
            return SkillMixScore(
                code: code,
                name: name,
                ratio: ratio,
                amount: amount,
                contactEmail: contactEmail,
                limit: limit,
                durationMinutes: durationMinutes,
                expiresAt: expiresAt,
                category: category,
                facility: facility,
                ward: ward,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a skill mix score in status draft.
    static func newSkillMixScore(_ code: String, name: String) -> SkillMixScore {
        return SkillMixScore(
            code: code,
            name: name,
            ratio: 0.0,
            amount: 0.0,
            contactEmail: "",
            limit: 0,
            durationMinutes: 0,
            expiresAt: 0,
            category: "",
            facility: "",
            ward: "",
            status: SkillMixScoreStatus.draft
        )
    }
}
