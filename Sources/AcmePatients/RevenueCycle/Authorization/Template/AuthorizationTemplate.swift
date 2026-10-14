import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a authorization template is in its life cycle.
    enum AuthorizationTemplateStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A authorization template. Its code is unique within a tenant.
    final class AuthorizationTemplate {
        var code: String
        var name: String
        var checksum: String
        var floorValue: Double
        var refills: Int
        var retries: Int
        var patientRef: String
        var graceDays: Int
        var maximum: Double
        var ownerID: String
        var amount: Double
        var status: AuthorizationTemplateStatus

        init(code: String, name: String, checksum: String, floorValue: Double, refills: Int, retries: Int, patientRef: String, graceDays: Int, maximum: Double, ownerID: String, amount: Double, status: AuthorizationTemplateStatus) {
            self.code = code
            self.name = name
            self.checksum = checksum
            self.floorValue = floorValue
            self.refills = refills
            self.retries = retries
            self.patientRef = patientRef
            self.graceDays = graceDays
            self.maximum = maximum
            self.ownerID = ownerID
            self.amount = amount
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AuthorizationTemplateStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == AuthorizationTemplateStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AuthorizationTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("authorization template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("authorization template") \(code)"
        }

        func netTotal() -> Double {
            return ((Double(retries) - floorValue) * 100).rounded() / 100
        }

        func copyValue() -> AuthorizationTemplate {
            return AuthorizationTemplate(
                code: code,
                name: name,
                checksum: checksum,
                floorValue: floorValue,
                refills: refills,
                retries: retries,
                patientRef: patientRef,
                graceDays: graceDays,
                maximum: maximum,
                ownerID: ownerID,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a authorization template in status created.
    static func newAuthorizationTemplate(_ code: String, name: String) -> AuthorizationTemplate {
        return AuthorizationTemplate(
            code: code,
            name: name,
            checksum: "",
            floorValue: 0.0,
            refills: 0,
            retries: 0,
            patientRef: "",
            graceDays: 0,
            maximum: 0.0,
            ownerID: "",
            amount: 0.0,
            status: AuthorizationTemplateStatus.created
        )
    }
}
