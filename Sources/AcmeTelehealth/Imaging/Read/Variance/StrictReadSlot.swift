import AcmePlatform
import Foundation

extension Imaging {
    /// Where a strict read slot is in its life cycle.
    enum StrictReadSlotStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a strict read slot and its current status.
    final class StrictReadSlot {
        var code: String
        var title: String
        var cost: Double
        var clinicianID: String
        var facility: String
        var externalRef: String
        var encounterID: String
        var payer: String
        var attributes: [String: String]
        var checksum: String
        var notes: String
        var status: StrictReadSlotStatus

        init(code: String, title: String, cost: Double, clinicianID: String, facility: String, externalRef: String, encounterID: String, payer: String, attributes: [String: String], checksum: String, notes: String, status: StrictReadSlotStatus) {
            self.code = code
            self.title = title
            self.cost = cost
            self.clinicianID = clinicianID
            self.facility = facility
            self.externalRef = externalRef
            self.encounterID = encounterID
            self.payer = payer
            self.attributes = attributes
            self.checksum = checksum
            self.notes = notes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: StrictReadSlotStatus) -> Bool {
            switch status {
            case .planned:
                return next == StrictReadSlotStatus.cancelled
            case .scheduled:
                return next == StrictReadSlotStatus.inProgress || next == StrictReadSlotStatus.cancelled
            case .inProgress:
                return next == StrictReadSlotStatus.cancelled
            case .completed:
                return next == StrictReadSlotStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictReadSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict read slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("strict read slot") \(code)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func measuredValue() -> Double {
            return cost
        }

        func copyValue() -> StrictReadSlot {
            return StrictReadSlot(
                code: code,
                title: title,
                cost: cost,
                clinicianID: clinicianID,
                facility: facility,
                externalRef: externalRef,
                encounterID: encounterID,
                payer: payer,
                attributes: attributes,
                checksum: checksum,
                notes: notes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a strict read slot in status planned.
    static func newStrictReadSlot(_ code: String, title: String) -> StrictReadSlot {
        return StrictReadSlot(
            code: code,
            title: title,
            cost: 0.0,
            clinicianID: "",
            facility: "",
            externalRef: "",
            encounterID: "",
            payer: "",
            attributes: [:],
            checksum: "",
            notes: "",
            status: StrictReadSlotStatus.planned
        )
    }
}
