import AcmePlatform
import Foundation

extension Imaging {
    /// Where a modality slot is in its life cycle.
    enum ModalitySlotStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A modality slot as the modality team keeps it.
    final class ModalitySlot {
        var code: String
        var label: String
        var acuity: Int
        var discount: Double
        var revision: Int
        var name: String
        var ceiling: Double
        var weight: Double
        var version: Int
        var amount: Double
        var externalRef: String
        var status: ModalitySlotStatus

        init(code: String, label: String, acuity: Int, discount: Double, revision: Int, name: String, ceiling: Double, weight: Double, version: Int, amount: Double, externalRef: String, status: ModalitySlotStatus) {
            self.code = code
            self.label = label
            self.acuity = acuity
            self.discount = discount
            self.revision = revision
            self.name = name
            self.ceiling = ceiling
            self.weight = weight
            self.version = version
            self.amount = amount
            self.externalRef = externalRef
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

        func canMoveTo(_ next: ModalitySlotStatus) -> Bool {
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
                return next == ModalitySlotStatus.rejected || next == ModalitySlotStatus.withdrawn
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

        func moveTo(_ next: ModalitySlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("modality slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\("modality slot") \(code)"
        }

        func adjustedExposure() -> Double {
            return (Double(revision) * discount * 100).rounded() / 100
        }

        func copyValue() -> ModalitySlot {
            return ModalitySlot(
                code: code,
                label: label,
                acuity: acuity,
                discount: discount,
                revision: revision,
                name: name,
                ceiling: ceiling,
                weight: weight,
                version: version,
                amount: amount,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a modality slot in status proposed.
    static func newModalitySlot(_ code: String, label: String) -> ModalitySlot {
        return ModalitySlot(
            code: code,
            label: label,
            acuity: 0,
            discount: 0.0,
            revision: 0,
            name: "",
            ceiling: 0.0,
            weight: 0.0,
            version: 0,
            amount: 0.0,
            externalRef: "",
            status: ModalitySlotStatus.proposed
        )
    }
}
