import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a lenient care gap rule is in its life cycle.
    enum LenientCareGapRuleStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A lenient care gap rule. Its code is unique within a tenant.
    final class LenientCareGapRule {
        var code: String
        var name: String
        var description: String
        var ratio: Double
        var visitMinutes: Int
        var updatedAt: Int
        var visible: Bool
        var score: Double
        var endsAt: Int
        var status: LenientCareGapRuleStatus

        init(code: String, name: String, description: String, ratio: Double, visitMinutes: Int, updatedAt: Int, visible: Bool, score: Double, endsAt: Int, status: LenientCareGapRuleStatus) {
            self.code = code
            self.name = name
            self.description = description
            self.ratio = ratio
            self.visitMinutes = visitMinutes
            self.updatedAt = updatedAt
            self.visible = visible
            self.score = score
            self.endsAt = endsAt
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

        func canMoveTo(_ next: LenientCareGapRuleStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == LenientCareGapRuleStatus.rejected || next == LenientCareGapRuleStatus.withdrawn
            case .rejected:
                return next == LenientCareGapRuleStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientCareGapRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient care gap rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("lenient care gap rule") \(code)"
        }

        func weightedVolume() -> Double {
            return ((Double(visitMinutes) - ratio) * 100).rounded() / 100
        }

        func copyValue() -> LenientCareGapRule {
            return LenientCareGapRule(
                code: code,
                name: name,
                description: description,
                ratio: ratio,
                visitMinutes: visitMinutes,
                updatedAt: updatedAt,
                visible: visible,
                score: score,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a lenient care gap rule in status proposed.
    static func newLenientCareGapRule(_ code: String, name: String) -> LenientCareGapRule {
        return LenientCareGapRule(
            code: code,
            name: name,
            description: "",
            ratio: 0.0,
            visitMinutes: 0,
            updatedAt: 0,
            visible: false,
            score: 0.0,
            endsAt: 0,
            status: LenientCareGapRuleStatus.proposed
        )
    }
}
