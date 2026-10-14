import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a capped order set template is in its life cycle.
    enum CappedOrderSetTemplateStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a capped order set template and its current status.
    final class CappedOrderSetTemplate {
        var code: String
        var name: String
        var payer: String
        var weight: Double
        var copay: Double
        var ward: String
        var locale: String
        var quantity: Int
        var status: CappedOrderSetTemplateStatus

        init(code: String, name: String, payer: String, weight: Double, copay: Double, ward: String, locale: String, quantity: Int, status: CappedOrderSetTemplateStatus) {
            self.code = code
            self.name = name
            self.payer = payer
            self.weight = weight
            self.copay = copay
            self.ward = ward
            self.locale = locale
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

        func canMoveTo(_ next: CappedOrderSetTemplateStatus) -> Bool {
            switch status {
            case .proposed:
                return next == CappedOrderSetTemplateStatus.withdrawn
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == CappedOrderSetTemplateStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedOrderSetTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped order set template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("capped order set template") \(code)"
        }

        func adjustedLoad() -> Double {
            return (weight * Double(quantity) * 100).rounded() / 100
        }

        func copyValue() -> CappedOrderSetTemplate {
            return CappedOrderSetTemplate(
                code: code,
                name: name,
                payer: payer,
                weight: weight,
                copay: copay,
                ward: ward,
                locale: locale,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a capped order set template in status proposed.
    static func newCappedOrderSetTemplate(_ code: String, name: String) -> CappedOrderSetTemplate {
        return CappedOrderSetTemplate(
            code: code,
            name: name,
            payer: "",
            weight: 0.0,
            copay: 0.0,
            ward: "",
            locale: "",
            quantity: 0,
            status: CappedOrderSetTemplateStatus.proposed
        )
    }
}
