import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a adaptive bed board slot is in its life cycle.
    enum AdaptiveBedBoardSlotStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a adaptive bed board slot and its current status.
    final class AdaptiveBedBoardSlot {
        var code: String
        var name: String
        var capacity: Int
        var visible: Bool
        var unit: String
        var patientRef: String
        var source: String
        var ownerID: String
        var currency: String
        var dosageMg: Double
        var status: AdaptiveBedBoardSlotStatus

        init(code: String, name: String, capacity: Int, visible: Bool, unit: String, patientRef: String, source: String, ownerID: String, currency: String, dosageMg: Double, status: AdaptiveBedBoardSlotStatus) {
            self.code = code
            self.name = name
            self.capacity = capacity
            self.visible = visible
            self.unit = unit
            self.patientRef = patientRef
            self.source = source
            self.ownerID = ownerID
            self.currency = currency
            self.dosageMg = dosageMg
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AdaptiveBedBoardSlotStatus) -> Bool {
            switch status {
            case .created:
                return next == AdaptiveBedBoardSlotStatus.validated || next == AdaptiveBedBoardSlotStatus.published
            case .validated:
                return next == AdaptiveBedBoardSlotStatus.published
            case .published:
                return next == AdaptiveBedBoardSlotStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveBedBoardSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive bed board slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func weightedLoad() -> Double {
            return (dosageMg * Double(capacity) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveBedBoardSlot {
            return AdaptiveBedBoardSlot(
                code: code,
                name: name,
                capacity: capacity,
                visible: visible,
                unit: unit,
                patientRef: patientRef,
                source: source,
                ownerID: ownerID,
                currency: currency,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a adaptive bed board slot in status created.
    static func newAdaptiveBedBoardSlot(_ code: String, name: String) -> AdaptiveBedBoardSlot {
        return AdaptiveBedBoardSlot(
            code: code,
            name: name,
            capacity: 0,
            visible: false,
            unit: "",
            patientRef: "",
            source: "",
            ownerID: "",
            currency: "",
            dosageMg: 0.0,
            status: AdaptiveBedBoardSlotStatus.created
        )
    }
}
