import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a census budget is in its life cycle.
    enum CensusBudgetStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A census budget as the census team keeps it.
    final class CensusBudget {
        var code: String
        var title: String
        var floorValue: Double
        var currency: String
        var unit: String
        var payer: String
        var facility: String
        var checksum: String
        var durationMinutes: Int
        var notes: String
        var status: CensusBudgetStatus

        init(code: String, title: String, floorValue: Double, currency: String, unit: String, payer: String, facility: String, checksum: String, durationMinutes: Int, notes: String, status: CensusBudgetStatus) {
            self.code = code
            self.title = title
            self.floorValue = floorValue
            self.currency = currency
            self.unit = unit
            self.payer = payer
            self.facility = facility
            self.checksum = checksum
            self.durationMinutes = durationMinutes
            self.notes = notes
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

        func canMoveTo(_ next: CensusBudgetStatus) -> Bool {
            switch status {
            case .requested:
                return next == CensusBudgetStatus.granted || next == CensusBudgetStatus.expired
            case .granted:
                return next == CensusBudgetStatus.expired
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

        func moveTo(_ next: CensusBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("census budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func weightedExposure() -> Double {
            return ((Double(durationMinutes) + floorValue) * 100).rounded() / 100
        }

        func copyValue() -> CensusBudget {
            return CensusBudget(
                code: code,
                title: title,
                floorValue: floorValue,
                currency: currency,
                unit: unit,
                payer: payer,
                facility: facility,
                checksum: checksum,
                durationMinutes: durationMinutes,
                notes: notes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a census budget in status requested.
    static func newCensusBudget(_ code: String, title: String) -> CensusBudget {
        return CensusBudget(
            code: code,
            title: title,
            floorValue: 0.0,
            currency: "",
            unit: "",
            payer: "",
            facility: "",
            checksum: "",
            durationMinutes: 0,
            notes: "",
            status: CensusBudgetStatus.requested
        )
    }
}
