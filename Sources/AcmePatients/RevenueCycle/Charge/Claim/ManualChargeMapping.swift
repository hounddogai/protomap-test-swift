import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a manual charge mapping is in its life cycle.
    enum ManualChargeMappingStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A manual charge mapping. Its code is unique within a tenant.
    final class ManualChargeMapping {
        var code: String
        var title: String
        var segment: String
        var sequence: Int
        var margin: Double
        var currency: String
        var visible: Bool
        var payer: String
        var timezone: String
        var facility: String
        var country: String
        var status: ManualChargeMappingStatus

        init(code: String, title: String, segment: String, sequence: Int, margin: Double, currency: String, visible: Bool, payer: String, timezone: String, facility: String, country: String, status: ManualChargeMappingStatus) {
            self.code = code
            self.title = title
            self.segment = segment
            self.sequence = sequence
            self.margin = margin
            self.currency = currency
            self.visible = visible
            self.payer = payer
            self.timezone = timezone
            self.facility = facility
            self.country = country
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

        func canMoveTo(_ next: ManualChargeMappingStatus) -> Bool {
            switch status {
            case .proposed:
                return next == ManualChargeMappingStatus.approved || next == ManualChargeMappingStatus.withdrawn
            case .approved:
                return next == ManualChargeMappingStatus.rejected || next == ManualChargeMappingStatus.withdrawn
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

        func moveTo(_ next: ManualChargeMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual charge mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func weightedLoad() -> Double {
            return (Double(sequence) * margin * 100).rounded() / 100
        }

        func copyValue() -> ManualChargeMapping {
            return ManualChargeMapping(
                code: code,
                title: title,
                segment: segment,
                sequence: sequence,
                margin: margin,
                currency: currency,
                visible: visible,
                payer: payer,
                timezone: timezone,
                facility: facility,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a manual charge mapping in status proposed.
    static func newManualChargeMapping(_ code: String, title: String) -> ManualChargeMapping {
        return ManualChargeMapping(
            code: code,
            title: title,
            segment: "",
            sequence: 0,
            margin: 0.0,
            currency: "",
            visible: false,
            payer: "",
            timezone: "",
            facility: "",
            country: "",
            status: ManualChargeMappingStatus.proposed
        )
    }
}
