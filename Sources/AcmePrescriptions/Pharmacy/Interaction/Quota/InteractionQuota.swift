import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a interaction quota is in its life cycle.
    enum InteractionQuotaStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One interaction quota, with what the planners need to act on it.
    final class InteractionQuota {
        var code: String
        var label: String
        var sequence: Int
        var discount: Double
        var checksum: String
        var ceiling: Double
        var amount: Double
        var retries: Int
        var unit: String
        var batchSize: Int
        var status: InteractionQuotaStatus

        init(code: String, label: String, sequence: Int, discount: Double, checksum: String, ceiling: Double, amount: Double, retries: Int, unit: String, batchSize: Int, status: InteractionQuotaStatus) {
            self.code = code
            self.label = label
            self.sequence = sequence
            self.discount = discount
            self.checksum = checksum
            self.ceiling = ceiling
            self.amount = amount
            self.retries = retries
            self.unit = unit
            self.batchSize = batchSize
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

        func canMoveTo(_ next: InteractionQuotaStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .expired:
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
                return next == InteractionQuotaStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: InteractionQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("interaction quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func netVolume() -> Double {
            return (Double(sequence) * ceiling * 100).rounded() / 100
        }

        func copyValue() -> InteractionQuota {
            return InteractionQuota(
                code: code,
                label: label,
                sequence: sequence,
                discount: discount,
                checksum: checksum,
                ceiling: ceiling,
                amount: amount,
                retries: retries,
                unit: unit,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a interaction quota in status requested.
    static func newInteractionQuota(_ code: String, label: String) -> InteractionQuota {
        return InteractionQuota(
            code: code,
            label: label,
            sequence: 0,
            discount: 0.0,
            checksum: "",
            ceiling: 0.0,
            amount: 0.0,
            retries: 0,
            unit: "",
            batchSize: 0,
            status: InteractionQuotaStatus.requested
        )
    }
}
