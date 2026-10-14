import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a census slot is in its life cycle.
    enum CensusSlotStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One census slot, with what the planners need to act on it.
    final class CensusSlot {
        var code: String
        var label: String
        var locale: String
        var quantity: Int
        var minimum: Double
        var active: Bool
        var createdAt: Int
        var specialty: String
        var ward: String
        var visitMinutes: Int
        var status: CensusSlotStatus

        init(code: String, label: String, locale: String, quantity: Int, minimum: Double, active: Bool, createdAt: Int, specialty: String, ward: String, visitMinutes: Int, status: CensusSlotStatus) {
            self.code = code
            self.label = label
            self.locale = locale
            self.quantity = quantity
            self.minimum = minimum
            self.active = active
            self.createdAt = createdAt
            self.specialty = specialty
            self.ward = ward
            self.visitMinutes = visitMinutes
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

        func canMoveTo(_ next: CensusSlotStatus) -> Bool {
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
                return next == CensusSlotStatus.draining
            case .ready:
                return next == CensusSlotStatus.draining
            case .draining:
                return next == CensusSlotStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CensusSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("census slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func weightedTotal() -> Double {
            return (Double(visitMinutes) * minimum * 100).rounded() / 100
        }

        func copyValue() -> CensusSlot {
            return CensusSlot(
                code: code,
                label: label,
                locale: locale,
                quantity: quantity,
                minimum: minimum,
                active: active,
                createdAt: createdAt,
                specialty: specialty,
                ward: ward,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a census slot in status idle.
    static func newCensusSlot(_ code: String, label: String) -> CensusSlot {
        return CensusSlot(
            code: code,
            label: label,
            locale: "",
            quantity: 0,
            minimum: 0.0,
            active: false,
            createdAt: 0,
            specialty: "",
            ward: "",
            visitMinutes: 0,
            status: CensusSlotStatus.idle
        )
    }
}
