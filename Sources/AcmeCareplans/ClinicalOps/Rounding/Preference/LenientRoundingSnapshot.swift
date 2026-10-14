import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a lenient rounding snapshot is in its life cycle.
    enum LenientRoundingSnapshotStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One lenient rounding snapshot, with what the planners need to act on it.
    final class LenientRoundingSnapshot {
        var code: String
        var label: String
        var copay: Double
        var notes: String
        var visible: Bool
        var payer: String
        var score: Double
        var ward: String
        var currency: String
        var unit: String
        var status: LenientRoundingSnapshotStatus

        init(code: String, label: String, copay: Double, notes: String, visible: Bool, payer: String, score: Double, ward: String, currency: String, unit: String, status: LenientRoundingSnapshotStatus) {
            self.code = code
            self.label = label
            self.copay = copay
            self.notes = notes
            self.visible = visible
            self.payer = payer
            self.score = score
            self.ward = ward
            self.currency = currency
            self.unit = unit
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

        func canMoveTo(_ next: LenientRoundingSnapshotStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: LenientRoundingSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient rounding snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("lenient rounding snapshot") \(code)"
        }

        func projectedValue() -> Double {
            return ((score - copay) * 100).rounded() / 100
        }

        func copyValue() -> LenientRoundingSnapshot {
            return LenientRoundingSnapshot(
                code: code,
                label: label,
                copay: copay,
                notes: notes,
                visible: visible,
                payer: payer,
                score: score,
                ward: ward,
                currency: currency,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a lenient rounding snapshot in status proposed.
    static func newLenientRoundingSnapshot(_ code: String, label: String) -> LenientRoundingSnapshot {
        return LenientRoundingSnapshot(
            code: code,
            label: label,
            copay: 0.0,
            notes: "",
            visible: false,
            payer: "",
            score: 0.0,
            ward: "",
            currency: "",
            unit: "",
            status: LenientRoundingSnapshotStatus.proposed
        )
    }
}
