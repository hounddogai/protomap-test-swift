import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a dispense adjustment is in its life cycle.
    enum DispenseAdjustmentStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A dispense adjustment as the dispense team keeps it.
    final class DispenseAdjustment {
        var code: String
        var name: String
        var contactEmail: String
        var encounterID: String
        var endsAt: Int
        var ward: String
        var status: DispenseAdjustmentStatus

        init(code: String, name: String, contactEmail: String, encounterID: String, endsAt: Int, ward: String, status: DispenseAdjustmentStatus) {
            self.code = code
            self.name = name
            self.contactEmail = contactEmail
            self.encounterID = encounterID
            self.endsAt = endsAt
            self.ward = ward
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

        func canMoveTo(_ next: DispenseAdjustmentStatus) -> Bool {
            switch status {
            case .idle:
                return next == DispenseAdjustmentStatus.warming || next == DispenseAdjustmentStatus.draining
            case .warming:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == DispenseAdjustmentStatus.draining || next == DispenseAdjustmentStatus.stopped
            case .draining:
                return next == DispenseAdjustmentStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DispenseAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("dispense adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("dispense adjustment") \(code)"
        }

        func measuredValue() -> Double {
            return Double(endsAt)
        }

        func copyValue() -> DispenseAdjustment {
            return DispenseAdjustment(
                code: code,
                name: name,
                contactEmail: contactEmail,
                encounterID: encounterID,
                endsAt: endsAt,
                ward: ward,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a dispense adjustment in status idle.
    static func newDispenseAdjustment(_ code: String, name: String) -> DispenseAdjustment {
        return DispenseAdjustment(
            code: code,
            name: name,
            contactEmail: "",
            encounterID: "",
            endsAt: 0,
            ward: "",
            status: DispenseAdjustmentStatus.idle
        )
    }
}
