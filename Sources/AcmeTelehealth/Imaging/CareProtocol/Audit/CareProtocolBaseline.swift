import AcmePlatform
import Foundation

extension Imaging {
    /// Where a care protocol baseline is in its life cycle.
    enum CareProtocolBaselineStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A care protocol baseline. Its code is unique within a tenant.
    final class CareProtocolBaseline {
        var code: String
        var name: String
        var active: Bool
        var payer: String
        var specialty: String
        var category: String
        var facility: String
        var ownerID: String
        var visible: Bool
        var minimum: Double
        var status: CareProtocolBaselineStatus

        init(code: String, name: String, active: Bool, payer: String, specialty: String, category: String, facility: String, ownerID: String, visible: Bool, minimum: Double, status: CareProtocolBaselineStatus) {
            self.code = code
            self.name = name
            self.active = active
            self.payer = payer
            self.specialty = specialty
            self.category = category
            self.facility = facility
            self.ownerID = ownerID
            self.visible = visible
            self.minimum = minimum
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

        func canMoveTo(_ next: CareProtocolBaselineStatus) -> Bool {
            switch status {
            case .requested:
                return next == CareProtocolBaselineStatus.granted || next == CareProtocolBaselineStatus.revoked
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == CareProtocolBaselineStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareProtocolBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("care protocol baseline") \(code)"
        }

        func measuredValue() -> Double {
            return minimum
        }

        func copyValue() -> CareProtocolBaseline {
            return CareProtocolBaseline(
                code: code,
                name: name,
                active: active,
                payer: payer,
                specialty: specialty,
                category: category,
                facility: facility,
                ownerID: ownerID,
                visible: visible,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a care protocol baseline in status requested.
    static func newCareProtocolBaseline(_ code: String, name: String) -> CareProtocolBaseline {
        return CareProtocolBaseline(
            code: code,
            name: name,
            active: false,
            payer: "",
            specialty: "",
            category: "",
            facility: "",
            ownerID: "",
            visible: false,
            minimum: 0.0,
            status: CareProtocolBaselineStatus.requested
        )
    }
}
