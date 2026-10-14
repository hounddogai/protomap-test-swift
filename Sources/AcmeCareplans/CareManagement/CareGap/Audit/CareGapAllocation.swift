import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a care gap allocation is in its life cycle.
    enum CareGapAllocationStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A care gap allocation. Its code is unique within a tenant.
    final class CareGapAllocation {
        var code: String
        var label: String
        var ward: String
        var encounterID: String
        var country: String
        var quantity: Int
        var status: CareGapAllocationStatus

        init(code: String, label: String, ward: String, encounterID: String, country: String, quantity: Int, status: CareGapAllocationStatus) {
            self.code = code
            self.label = label
            self.ward = ward
            self.encounterID = encounterID
            self.country = country
            self.quantity = quantity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CareGapAllocationStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == CareGapAllocationStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareGapAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care gap allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> CareGapAllocation {
            return CareGapAllocation(
                code: code,
                label: label,
                ward: ward,
                encounterID: encounterID,
                country: country,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a care gap allocation in status draft.
    static func newCareGapAllocation(_ code: String, label: String) -> CareGapAllocation {
        return CareGapAllocation(
            code: code,
            label: label,
            ward: "",
            encounterID: "",
            country: "",
            quantity: 0,
            status: CareGapAllocationStatus.draft
        )
    }
}
