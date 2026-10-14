import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a tiered formulary template is in its life cycle.
    enum TieredFormularyTemplateStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A tiered formulary template. Its code is unique within a tenant.
    final class TieredFormularyTemplate {
        var code: String
        var label: String
        var createdAt: Int
        var attempts: Int
        var limit: Int
        var payer: String
        var status: TieredFormularyTemplateStatus

        init(code: String, label: String, createdAt: Int, attempts: Int, limit: Int, payer: String, status: TieredFormularyTemplateStatus) {
            self.code = code
            self.label = label
            self.createdAt = createdAt
            self.attempts = attempts
            self.limit = limit
            self.payer = payer
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

        func canMoveTo(_ next: TieredFormularyTemplateStatus) -> Bool {
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
                return next == TieredFormularyTemplateStatus.active || next == TieredFormularyTemplateStatus.suspended
            case .active:
                return next == TieredFormularyTemplateStatus.closed
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

        func moveTo(_ next: TieredFormularyTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered formulary template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func effectiveLoad() -> Double {
            return (Double(attempts) * Double(createdAt) * 100).rounded() / 100
        }

        func copyValue() -> TieredFormularyTemplate {
            return TieredFormularyTemplate(
                code: code,
                label: label,
                createdAt: createdAt,
                attempts: attempts,
                limit: limit,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a tiered formulary template in status draft.
    static func newTieredFormularyTemplate(_ code: String, label: String) -> TieredFormularyTemplate {
        return TieredFormularyTemplate(
            code: code,
            label: label,
            createdAt: 0,
            attempts: 0,
            limit: 0,
            payer: "",
            status: TieredFormularyTemplateStatus.draft
        )
    }
}
