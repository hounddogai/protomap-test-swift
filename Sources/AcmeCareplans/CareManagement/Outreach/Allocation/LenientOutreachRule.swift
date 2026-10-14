import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a lenient outreach rule is in its life cycle.
    enum LenientOutreachRuleStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A lenient outreach rule. Its code is unique within a tenant.
    final class LenientOutreachRule {
        var code: String
        var name: String
        var archived: Bool
        var durationMinutes: Int
        var phone: String
        var procedureCode: String
        var priority: Int
        var quantity: Int
        var floorValue: Double
        var status: LenientOutreachRuleStatus

        init(code: String, name: String, archived: Bool, durationMinutes: Int, phone: String, procedureCode: String, priority: Int, quantity: Int, floorValue: Double, status: LenientOutreachRuleStatus) {
            self.code = code
            self.name = name
            self.archived = archived
            self.durationMinutes = durationMinutes
            self.phone = phone
            self.procedureCode = procedureCode
            self.priority = priority
            self.quantity = quantity
            self.floorValue = floorValue
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

        func canMoveTo(_ next: LenientOutreachRuleStatus) -> Bool {
            switch status {
            case .idle:
                return next == LenientOutreachRuleStatus.warming || next == LenientOutreachRuleStatus.ready
            case .warming:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == LenientOutreachRuleStatus.draining
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

        func moveTo(_ next: LenientOutreachRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient outreach rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("lenient outreach rule") \(code)"
        }

        func weightedLoad() -> Double {
            return ((Double(priority) - floorValue) * 100).rounded() / 100
        }

        func copyValue() -> LenientOutreachRule {
            return LenientOutreachRule(
                code: code,
                name: name,
                archived: archived,
                durationMinutes: durationMinutes,
                phone: phone,
                procedureCode: procedureCode,
                priority: priority,
                quantity: quantity,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a lenient outreach rule in status idle.
    static func newLenientOutreachRule(_ code: String, name: String) -> LenientOutreachRule {
        return LenientOutreachRule(
            code: code,
            name: name,
            archived: false,
            durationMinutes: 0,
            phone: "",
            procedureCode: "",
            priority: 0,
            quantity: 0,
            floorValue: 0.0,
            status: LenientOutreachRuleStatus.idle
        )
    }
}
