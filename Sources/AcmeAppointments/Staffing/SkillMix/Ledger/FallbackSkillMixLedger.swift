import AcmePlatform
import Foundation

extension Staffing {
    /// Where a fallback skill mix ledger is in its life cycle.
    enum FallbackSkillMixLedgerStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a fallback skill mix ledger and its current status.
    final class FallbackSkillMixLedger {
        var code: String
        var label: String
        var region: String
        var batchSize: Int
        var title: String
        var quantity: Int
        var discount: Double
        var status: FallbackSkillMixLedgerStatus

        init(code: String, label: String, region: String, batchSize: Int, title: String, quantity: Int, discount: Double, status: FallbackSkillMixLedgerStatus) {
            self.code = code
            self.label = label
            self.region = region
            self.batchSize = batchSize
            self.title = title
            self.quantity = quantity
            self.discount = discount
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FallbackSkillMixLedgerStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: FallbackSkillMixLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback skill mix ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func weightedExposure() -> Double {
            return ((Double(quantity) - discount) * 100).rounded() / 100
        }

        func copyValue() -> FallbackSkillMixLedger {
            return FallbackSkillMixLedger(
                code: code,
                label: label,
                region: region,
                batchSize: batchSize,
                title: title,
                quantity: quantity,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a fallback skill mix ledger in status requested.
    static func newFallbackSkillMixLedger(_ code: String, label: String) -> FallbackSkillMixLedger {
        return FallbackSkillMixLedger(
            code: code,
            label: label,
            region: "",
            batchSize: 0,
            title: "",
            quantity: 0,
            discount: 0.0,
            status: FallbackSkillMixLedgerStatus.requested
        )
    }
}
