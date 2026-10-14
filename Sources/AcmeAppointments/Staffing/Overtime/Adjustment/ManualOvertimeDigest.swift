import AcmePlatform
import Foundation

extension Staffing {
    /// Where a manual overtime digest is in its life cycle.
    enum ManualOvertimeDigestStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A manual overtime digest. Its code is unique within a tenant.
    final class ManualOvertimeDigest {
        var code: String
        var name: String
        var category: String
        var copay: Double
        var discount: Double
        var visible: Bool
        var ward: String
        var clinicianID: String
        var procedureCode: String
        var status: ManualOvertimeDigestStatus

        init(code: String, name: String, category: String, copay: Double, discount: Double, visible: Bool, ward: String, clinicianID: String, procedureCode: String, status: ManualOvertimeDigestStatus) {
            self.code = code
            self.name = name
            self.category = category
            self.copay = copay
            self.discount = discount
            self.visible = visible
            self.ward = ward
            self.clinicianID = clinicianID
            self.procedureCode = procedureCode
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

        func canMoveTo(_ next: ManualOvertimeDigestStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == ManualOvertimeDigestStatus.expired
            case .revoked:
                return next == ManualOvertimeDigestStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualOvertimeDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual overtime digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func effectiveTotal() -> Double {
            return ((discount + copay) * 100).rounded() / 100
        }

        func copyValue() -> ManualOvertimeDigest {
            return ManualOvertimeDigest(
                code: code,
                name: name,
                category: category,
                copay: copay,
                discount: discount,
                visible: visible,
                ward: ward,
                clinicianID: clinicianID,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a manual overtime digest in status requested.
    static func newManualOvertimeDigest(_ code: String, name: String) -> ManualOvertimeDigest {
        return ManualOvertimeDigest(
            code: code,
            name: name,
            category: "",
            copay: 0.0,
            discount: 0.0,
            visible: false,
            ward: "",
            clinicianID: "",
            procedureCode: "",
            status: ManualOvertimeDigestStatus.requested
        )
    }
}
