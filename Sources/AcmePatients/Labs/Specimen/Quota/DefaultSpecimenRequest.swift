import AcmePlatform
import Foundation

extension Labs {
    /// Where a default specimen request is in its life cycle.
    enum DefaultSpecimenRequestStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a default specimen request and its current status.
    final class DefaultSpecimenRequest {
        var code: String
        var name: String
        var quantity: Int
        var discount: Double
        var limit: Int
        var allergy: String
        var refills: Int
        var payer: String
        var floorValue: Double
        var status: DefaultSpecimenRequestStatus

        init(code: String, name: String, quantity: Int, discount: Double, limit: Int, allergy: String, refills: Int, payer: String, floorValue: Double, status: DefaultSpecimenRequestStatus) {
            self.code = code
            self.name = name
            self.quantity = quantity
            self.discount = discount
            self.limit = limit
            self.allergy = allergy
            self.refills = refills
            self.payer = payer
            self.floorValue = floorValue
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

        func canMoveTo(_ next: DefaultSpecimenRequestStatus) -> Bool {
            switch status {
            case .requested:
                return next == DefaultSpecimenRequestStatus.expired
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == DefaultSpecimenRequestStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultSpecimenRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default specimen request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func effectiveLoad() -> Double {
            return (Double(quantity) * Double(limit) * 100).rounded() / 100
        }

        func copyValue() -> DefaultSpecimenRequest {
            return DefaultSpecimenRequest(
                code: code,
                name: name,
                quantity: quantity,
                discount: discount,
                limit: limit,
                allergy: allergy,
                refills: refills,
                payer: payer,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a default specimen request in status requested.
    static func newDefaultSpecimenRequest(_ code: String, name: String) -> DefaultSpecimenRequest {
        return DefaultSpecimenRequest(
            code: code,
            name: name,
            quantity: 0,
            discount: 0.0,
            limit: 0,
            allergy: "",
            refills: 0,
            payer: "",
            floorValue: 0.0,
            status: DefaultSpecimenRequestStatus.requested
        )
    }
}
