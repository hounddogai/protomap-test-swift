import AcmePlatform
import Foundation

extension Labs {
    /// Where a legacy accession baseline is in its life cycle.
    enum LegacyAccessionBaselineStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a legacy accession baseline and its current status.
    final class LegacyAccessionBaseline {
        var code: String
        var name: String
        var unit: String
        var checksum: String
        var active: Bool
        var specialty: String
        var encounterID: String
        var quantity: Int
        var status: LegacyAccessionBaselineStatus

        init(code: String, name: String, unit: String, checksum: String, active: Bool, specialty: String, encounterID: String, quantity: Int, status: LegacyAccessionBaselineStatus) {
            self.code = code
            self.name = name
            self.unit = unit
            self.checksum = checksum
            self.active = active
            self.specialty = specialty
            self.encounterID = encounterID
            self.quantity = quantity
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

        func canMoveTo(_ next: LegacyAccessionBaselineStatus) -> Bool {
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
                return next == LegacyAccessionBaselineStatus.rejected || next == LegacyAccessionBaselineStatus.withdrawn
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

        func moveTo(_ next: LegacyAccessionBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy accession baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> LegacyAccessionBaseline {
            return LegacyAccessionBaseline(
                code: code,
                name: name,
                unit: unit,
                checksum: checksum,
                active: active,
                specialty: specialty,
                encounterID: encounterID,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a legacy accession baseline in status proposed.
    static func newLegacyAccessionBaseline(_ code: String, name: String) -> LegacyAccessionBaseline {
        return LegacyAccessionBaseline(
            code: code,
            name: name,
            unit: "",
            checksum: "",
            active: false,
            specialty: "",
            encounterID: "",
            quantity: 0,
            status: LegacyAccessionBaselineStatus.proposed
        )
    }
}
