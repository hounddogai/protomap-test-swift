import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a legacy inventory rollup is in its life cycle.
    enum LegacyInventoryRollupStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A legacy inventory rollup as the inventory team keeps it.
    final class LegacyInventoryRollup {
        var code: String
        var label: String
        var procedureCode: String
        var unit: String
        var copay: Double
        var payer: String
        var maximum: Double
        var diagnosisCode: String
        var status: LegacyInventoryRollupStatus

        init(code: String, label: String, procedureCode: String, unit: String, copay: Double, payer: String, maximum: Double, diagnosisCode: String, status: LegacyInventoryRollupStatus) {
            self.code = code
            self.label = label
            self.procedureCode = procedureCode
            self.unit = unit
            self.copay = copay
            self.payer = payer
            self.maximum = maximum
            self.diagnosisCode = diagnosisCode
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

        func canMoveTo(_ next: LegacyInventoryRollupStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == LegacyInventoryRollupStatus.rejected || next == LegacyInventoryRollupStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: LegacyInventoryRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy inventory rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("legacy inventory rollup") \(code)"
        }

        func adjustedLoad() -> Double {
            return (copay * maximum * 100).rounded() / 100
        }

        func copyValue() -> LegacyInventoryRollup {
            return LegacyInventoryRollup(
                code: code,
                label: label,
                procedureCode: procedureCode,
                unit: unit,
                copay: copay,
                payer: payer,
                maximum: maximum,
                diagnosisCode: diagnosisCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a legacy inventory rollup in status proposed.
    static func newLegacyInventoryRollup(_ code: String, label: String) -> LegacyInventoryRollup {
        return LegacyInventoryRollup(
            code: code,
            label: label,
            procedureCode: "",
            unit: "",
            copay: 0.0,
            payer: "",
            maximum: 0.0,
            diagnosisCode: "",
            status: LegacyInventoryRollupStatus.proposed
        )
    }
}
