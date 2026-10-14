import AcmePlatform
import Foundation

extension Consent {
    /// Where a tiered revocation template is in its life cycle.
    enum TieredRevocationTemplateStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A tiered revocation template. Its code is unique within a tenant.
    final class TieredRevocationTemplate {
        var code: String
        var label: String
        var version: Int
        var active: Bool
        var sequence: Int
        var amount: Double
        var status: TieredRevocationTemplateStatus

        init(code: String, label: String, version: Int, active: Bool, sequence: Int, amount: Double, status: TieredRevocationTemplateStatus) {
            self.code = code
            self.label = label
            self.version = version
            self.active = active
            self.sequence = sequence
            self.amount = amount
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

        func canMoveTo(_ next: TieredRevocationTemplateStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == TieredRevocationTemplateStatus.reopened || next == TieredRevocationTemplateStatus.archived
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

        func moveTo(_ next: TieredRevocationTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered revocation template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\("tiered revocation template") \(code)"
        }

        func netExposure() -> Double {
            return ((Double(version) + amount) * 100).rounded() / 100
        }

        func copyValue() -> TieredRevocationTemplate {
            return TieredRevocationTemplate(
                code: code,
                label: label,
                version: version,
                active: active,
                sequence: sequence,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a tiered revocation template in status open.
    static func newTieredRevocationTemplate(_ code: String, label: String) -> TieredRevocationTemplate {
        return TieredRevocationTemplate(
            code: code,
            label: label,
            version: 0,
            active: false,
            sequence: 0,
            amount: 0.0,
            status: TieredRevocationTemplateStatus.`open`
        )
    }
}
