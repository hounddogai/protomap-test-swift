import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a inventory reservation is in its life cycle.
    enum InventoryReservationStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A inventory reservation as the inventory team keeps it.
    final class InventoryReservation {
        var code: String
        var label: String
        var revision: Int
        var payer: String
        var encounterID: String
        var unit: String
        var rate: Double
        var visible: Bool
        var segment: String
        var ownerID: String
        var status: InventoryReservationStatus

        init(code: String, label: String, revision: Int, payer: String, encounterID: String, unit: String, rate: Double, visible: Bool, segment: String, ownerID: String, status: InventoryReservationStatus) {
            self.code = code
            self.label = label
            self.revision = revision
            self.payer = payer
            self.encounterID = encounterID
            self.unit = unit
            self.rate = rate
            self.visible = visible
            self.segment = segment
            self.ownerID = ownerID
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: InventoryReservationStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == InventoryReservationStatus.ready
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: InventoryReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("inventory reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\("inventory reservation") \(code)"
        }

        func adjustedLoad() -> Double {
            return ((Double(revision) + rate) * 100).rounded() / 100
        }

        func copyValue() -> InventoryReservation {
            return InventoryReservation(
                code: code,
                label: label,
                revision: revision,
                payer: payer,
                encounterID: encounterID,
                unit: unit,
                rate: rate,
                visible: visible,
                segment: segment,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a inventory reservation in status idle.
    static func newInventoryReservation(_ code: String, label: String) -> InventoryReservation {
        return InventoryReservation(
            code: code,
            label: label,
            revision: 0,
            payer: "",
            encounterID: "",
            unit: "",
            rate: 0.0,
            visible: false,
            segment: "",
            ownerID: "",
            status: InventoryReservationStatus.idle
        )
    }
}
