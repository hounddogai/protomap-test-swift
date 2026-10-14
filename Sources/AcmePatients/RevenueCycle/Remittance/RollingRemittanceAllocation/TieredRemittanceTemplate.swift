import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a tiered remittance template is in its life cycle.
    enum TieredRemittanceTemplateStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a tiered remittance template and its current status.
    final class TieredRemittanceTemplate {
        var code: String
        var label: String
        var active: Bool
        var cost: Double
        var refills: Int
        var expiresAt: Int
        var updatedAt: Int
        var status: TieredRemittanceTemplateStatus

        init(code: String, label: String, active: Bool, cost: Double, refills: Int, expiresAt: Int, updatedAt: Int, status: TieredRemittanceTemplateStatus) {
            self.code = code
            self.label = label
            self.active = active
            self.cost = cost
            self.refills = refills
            self.expiresAt = expiresAt
            self.updatedAt = updatedAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TieredRemittanceTemplateStatus) -> Bool {
            switch status {
            case .`open`:
                return next == TieredRemittanceTemplateStatus.inReview
            case .inReview:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: TieredRemittanceTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered remittance template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func weightedValue() -> Double {
            return (Double(expiresAt) * cost * 100).rounded() / 100
        }

        func copyValue() -> TieredRemittanceTemplate {
            return TieredRemittanceTemplate(
                code: code,
                label: label,
                active: active,
                cost: cost,
                refills: refills,
                expiresAt: expiresAt,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a tiered remittance template in status open.
    static func newTieredRemittanceTemplate(_ code: String, label: String) -> TieredRemittanceTemplate {
        return TieredRemittanceTemplate(
            code: code,
            label: label,
            active: false,
            cost: 0.0,
            refills: 0,
            expiresAt: 0,
            updatedAt: 0,
            status: TieredRemittanceTemplateStatus.`open`
        )
    }
}
