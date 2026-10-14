import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a primary task rule is in its life cycle.
    enum PrimaryTaskRuleStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One primary task rule, with what the planners need to act on it.
    final class PrimaryTaskRule {
        var code: String
        var title: String
        var expiresAt: Int
        var quantity: Int
        var segment: String
        var visitMinutes: Int
        var bed: String
        var status: PrimaryTaskRuleStatus

        init(code: String, title: String, expiresAt: Int, quantity: Int, segment: String, visitMinutes: Int, bed: String, status: PrimaryTaskRuleStatus) {
            self.code = code
            self.title = title
            self.expiresAt = expiresAt
            self.quantity = quantity
            self.segment = segment
            self.visitMinutes = visitMinutes
            self.bed = bed
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

        func canMoveTo(_ next: PrimaryTaskRuleStatus) -> Bool {
            switch status {
            case .draft:
                return next == PrimaryTaskRuleStatus.pending || next == PrimaryTaskRuleStatus.active
            case .pending:
                switch next {
                case .suspended:
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

        func moveTo(_ next: PrimaryTaskRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary task rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func adjustedTotal() -> Double {
            return ((Double(visitMinutes) + Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryTaskRule {
            return PrimaryTaskRule(
                code: code,
                title: title,
                expiresAt: expiresAt,
                quantity: quantity,
                segment: segment,
                visitMinutes: visitMinutes,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a primary task rule in status draft.
    static func newPrimaryTaskRule(_ code: String, title: String) -> PrimaryTaskRule {
        return PrimaryTaskRule(
            code: code,
            title: title,
            expiresAt: 0,
            quantity: 0,
            segment: "",
            visitMinutes: 0,
            bed: "",
            status: PrimaryTaskRuleStatus.draft
        )
    }
}
