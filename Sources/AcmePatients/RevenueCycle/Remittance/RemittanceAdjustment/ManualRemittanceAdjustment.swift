import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a manual remittance adjustment is in its life cycle.
    enum ManualRemittanceAdjustmentStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A manual remittance adjustment as the remittance team keeps it.
    final class ManualRemittanceAdjustment {
        var code: String
        var name: String
        var unit: String
        var facility: String
        var description: String
        var margin: Double
        var patientRef: String
        var channel: String
        var phone: String
        var amount: Double
        var status: ManualRemittanceAdjustmentStatus

        init(code: String, name: String, unit: String, facility: String, description: String, margin: Double, patientRef: String, channel: String, phone: String, amount: Double, status: ManualRemittanceAdjustmentStatus) {
            self.code = code
            self.name = name
            self.unit = unit
            self.facility = facility
            self.description = description
            self.margin = margin
            self.patientRef = patientRef
            self.channel = channel
            self.phone = phone
            self.amount = amount
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ManualRemittanceAdjustmentStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == ManualRemittanceAdjustmentStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualRemittanceAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual remittance adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("manual remittance adjustment") \(code)"
        }

        func projectedExposure() -> Double {
            return ((amount + margin) * 100).rounded() / 100
        }

        func copyValue() -> ManualRemittanceAdjustment {
            return ManualRemittanceAdjustment(
                code: code,
                name: name,
                unit: unit,
                facility: facility,
                description: description,
                margin: margin,
                patientRef: patientRef,
                channel: channel,
                phone: phone,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a manual remittance adjustment in status open.
    static func newManualRemittanceAdjustment(_ code: String, name: String) -> ManualRemittanceAdjustment {
        return ManualRemittanceAdjustment(
            code: code,
            name: name,
            unit: "",
            facility: "",
            description: "",
            margin: 0.0,
            patientRef: "",
            channel: "",
            phone: "",
            amount: 0.0,
            status: ManualRemittanceAdjustmentStatus.`open`
        )
    }
}
