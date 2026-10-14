import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a dispense estimate is in its life cycle.
    enum DispenseEstimateStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A dispense estimate. Its code is unique within a tenant.
    final class DispenseEstimate {
        var code: String
        var title: String
        var contactEmail: String
        var patientRef: String
        var checksum: String
        var quantity: Int
        var status: DispenseEstimateStatus

        init(code: String, title: String, contactEmail: String, patientRef: String, checksum: String, quantity: Int, status: DispenseEstimateStatus) {
            self.code = code
            self.title = title
            self.contactEmail = contactEmail
            self.patientRef = patientRef
            self.checksum = checksum
            self.quantity = quantity
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

        func canMoveTo(_ next: DispenseEstimateStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == DispenseEstimateStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DispenseEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("dispense estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("dispense estimate") \(code)"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> DispenseEstimate {
            return DispenseEstimate(
                code: code,
                title: title,
                contactEmail: contactEmail,
                patientRef: patientRef,
                checksum: checksum,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a dispense estimate in status requested.
    static func newDispenseEstimate(_ code: String, title: String) -> DispenseEstimate {
        return DispenseEstimate(
            code: code,
            title: title,
            contactEmail: "",
            patientRef: "",
            checksum: "",
            quantity: 0,
            status: DispenseEstimateStatus.requested
        )
    }
}
