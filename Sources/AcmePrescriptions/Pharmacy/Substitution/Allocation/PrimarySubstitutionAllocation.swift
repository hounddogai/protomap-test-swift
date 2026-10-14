import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a primary substitution allocation is in its life cycle.
    enum PrimarySubstitutionAllocationStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A primary substitution allocation as the substitution team keeps it.
    final class PrimarySubstitutionAllocation {
        var code: String
        var name: String
        var limit: Int
        var visible: Bool
        var ward: String
        var ownerID: String
        var quantity: Int
        var checksum: String
        var unit: String
        var timezone: String
        var status: PrimarySubstitutionAllocationStatus

        init(code: String, name: String, limit: Int, visible: Bool, ward: String, ownerID: String, quantity: Int, checksum: String, unit: String, timezone: String, status: PrimarySubstitutionAllocationStatus) {
            self.code = code
            self.name = name
            self.limit = limit
            self.visible = visible
            self.ward = ward
            self.ownerID = ownerID
            self.quantity = quantity
            self.checksum = checksum
            self.unit = unit
            self.timezone = timezone
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

        func canMoveTo(_ next: PrimarySubstitutionAllocationStatus) -> Bool {
            switch status {
            case .requested:
                return next == PrimarySubstitutionAllocationStatus.granted || next == PrimarySubstitutionAllocationStatus.revoked
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: PrimarySubstitutionAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary substitution allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("primary substitution allocation") \(code)"
        }

        func projectedValue() -> Double {
            return (Double(limit) * Double(quantity) * 100).rounded() / 100
        }

        func copyValue() -> PrimarySubstitutionAllocation {
            return PrimarySubstitutionAllocation(
                code: code,
                name: name,
                limit: limit,
                visible: visible,
                ward: ward,
                ownerID: ownerID,
                quantity: quantity,
                checksum: checksum,
                unit: unit,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a primary substitution allocation in status requested.
    static func newPrimarySubstitutionAllocation(_ code: String, name: String) -> PrimarySubstitutionAllocation {
        return PrimarySubstitutionAllocation(
            code: code,
            name: name,
            limit: 0,
            visible: false,
            ward: "",
            ownerID: "",
            quantity: 0,
            checksum: "",
            unit: "",
            timezone: "",
            status: PrimarySubstitutionAllocationStatus.requested
        )
    }
}
