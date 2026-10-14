import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a interaction slot is in its life cycle.
    enum InteractionSlotStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A interaction slot as the interaction team keeps it.
    final class InteractionSlot {
        var code: String
        var name: String
        var encounterID: String
        var batchSize: Int
        var unit: String
        var discount: Double
        var diagnosisCode: String
        var status: InteractionSlotStatus

        init(code: String, name: String, encounterID: String, batchSize: Int, unit: String, discount: Double, diagnosisCode: String, status: InteractionSlotStatus) {
            self.code = code
            self.name = name
            self.encounterID = encounterID
            self.batchSize = batchSize
            self.unit = unit
            self.discount = discount
            self.diagnosisCode = diagnosisCode
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: InteractionSlotStatus) -> Bool {
            switch status {
            case .new:
                return next == InteractionSlotStatus.failed
            case .queued:
                return next == InteractionSlotStatus.running || next == InteractionSlotStatus.failed
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == InteractionSlotStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: InteractionSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("interaction slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func adjustedTotal() -> Double {
            return (Double(batchSize) * discount * 100).rounded() / 100
        }

        func copyValue() -> InteractionSlot {
            return InteractionSlot(
                code: code,
                name: name,
                encounterID: encounterID,
                batchSize: batchSize,
                unit: unit,
                discount: discount,
                diagnosisCode: diagnosisCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a interaction slot in status new.
    static func newInteractionSlot(_ code: String, name: String) -> InteractionSlot {
        return InteractionSlot(
            code: code,
            name: name,
            encounterID: "",
            batchSize: 0,
            unit: "",
            discount: 0.0,
            diagnosisCode: "",
            status: InteractionSlotStatus.new
        )
    }
}
