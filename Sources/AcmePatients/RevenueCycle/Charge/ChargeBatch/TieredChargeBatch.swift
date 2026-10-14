import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a tiered charge batch is in its life cycle.
    enum TieredChargeBatchStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One tiered charge batch, with what the planners need to act on it.
    final class TieredChargeBatch {
        var code: String
        var label: String
        var refills: Int
        var priority: Int
        var currency: String
        var diagnosisCode: String
        var sequence: Int
        var limit: Int
        var windowDays: Int
        var bed: String
        var status: TieredChargeBatchStatus

        init(code: String, label: String, refills: Int, priority: Int, currency: String, diagnosisCode: String, sequence: Int, limit: Int, windowDays: Int, bed: String, status: TieredChargeBatchStatus) {
            self.code = code
            self.label = label
            self.refills = refills
            self.priority = priority
            self.currency = currency
            self.diagnosisCode = diagnosisCode
            self.sequence = sequence
            self.limit = limit
            self.windowDays = windowDays
            self.bed = bed
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

        func canMoveTo(_ next: TieredChargeBatchStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == TieredChargeBatchStatus.revoked || next == TieredChargeBatchStatus.expired
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

        func moveTo(_ next: TieredChargeBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered charge batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func weightedLoad() -> Double {
            return ((Double(sequence) + Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> TieredChargeBatch {
            return TieredChargeBatch(
                code: code,
                label: label,
                refills: refills,
                priority: priority,
                currency: currency,
                diagnosisCode: diagnosisCode,
                sequence: sequence,
                limit: limit,
                windowDays: windowDays,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a tiered charge batch in status requested.
    static func newTieredChargeBatch(_ code: String, label: String) -> TieredChargeBatch {
        return TieredChargeBatch(
            code: code,
            label: label,
            refills: 0,
            priority: 0,
            currency: "",
            diagnosisCode: "",
            sequence: 0,
            limit: 0,
            windowDays: 0,
            bed: "",
            status: TieredChargeBatchStatus.requested
        )
    }
}
