import AcmePlatform
import Foundation

extension Staffing {
    /// Where a strict skill mix template is in its life cycle.
    enum StrictSkillMixTemplateStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One strict skill mix template, with what the planners need to act on it.
    final class StrictSkillMixTemplate {
        var code: String
        var title: String
        var amount: Double
        var quantity: Int
        var durationMinutes: Int
        var contactEmail: String
        var attempts: Int
        var floorValue: Double
        var revision: Int
        var margin: Double
        var ratio: Double
        var status: StrictSkillMixTemplateStatus

        init(code: String, title: String, amount: Double, quantity: Int, durationMinutes: Int, contactEmail: String, attempts: Int, floorValue: Double, revision: Int, margin: Double, ratio: Double, status: StrictSkillMixTemplateStatus) {
            self.code = code
            self.title = title
            self.amount = amount
            self.quantity = quantity
            self.durationMinutes = durationMinutes
            self.contactEmail = contactEmail
            self.attempts = attempts
            self.floorValue = floorValue
            self.revision = revision
            self.margin = margin
            self.ratio = ratio
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

        func canMoveTo(_ next: StrictSkillMixTemplateStatus) -> Bool {
            switch status {
            case .draft:
                return next == StrictSkillMixTemplateStatus.active || next == StrictSkillMixTemplateStatus.suspended
            case .pending:
                return next == StrictSkillMixTemplateStatus.active || next == StrictSkillMixTemplateStatus.closed
            case .active:
                return next == StrictSkillMixTemplateStatus.suspended
            case .suspended:
                return next == StrictSkillMixTemplateStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictSkillMixTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict skill mix template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func effectiveExposure() -> Double {
            return ((Double(attempts) + margin) * 100).rounded() / 100
        }

        func copyValue() -> StrictSkillMixTemplate {
            return StrictSkillMixTemplate(
                code: code,
                title: title,
                amount: amount,
                quantity: quantity,
                durationMinutes: durationMinutes,
                contactEmail: contactEmail,
                attempts: attempts,
                floorValue: floorValue,
                revision: revision,
                margin: margin,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a strict skill mix template in status draft.
    static func newStrictSkillMixTemplate(_ code: String, title: String) -> StrictSkillMixTemplate {
        return StrictSkillMixTemplate(
            code: code,
            title: title,
            amount: 0.0,
            quantity: 0,
            durationMinutes: 0,
            contactEmail: "",
            attempts: 0,
            floorValue: 0.0,
            revision: 0,
            margin: 0.0,
            ratio: 0.0,
            status: StrictSkillMixTemplateStatus.draft
        )
    }
}
