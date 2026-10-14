import AcmePlatform
import Foundation

extension Imaging {
    /// Where a care protocol threshold is in its life cycle.
    enum CareProtocolThresholdStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A care protocol threshold. Its code is unique within a tenant.
    final class CareProtocolThreshold {
        var code: String
        var name: String
        var patientRef: String
        var country: String
        var phone: String
        var dosageMg: Double
        var ceiling: Double
        var status: CareProtocolThresholdStatus

        init(code: String, name: String, patientRef: String, country: String, phone: String, dosageMg: Double, ceiling: Double, status: CareProtocolThresholdStatus) {
            self.code = code
            self.name = name
            self.patientRef = patientRef
            self.country = country
            self.phone = phone
            self.dosageMg = dosageMg
            self.ceiling = ceiling
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

        func canMoveTo(_ next: CareProtocolThresholdStatus) -> Bool {
            switch status {
            case .proposed:
                return next == CareProtocolThresholdStatus.rejected || next == CareProtocolThresholdStatus.withdrawn
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == CareProtocolThresholdStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareProtocolThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func weightedTotal() -> Double {
            return ((ceiling - dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolThreshold {
            return CareProtocolThreshold(
                code: code,
                name: name,
                patientRef: patientRef,
                country: country,
                phone: phone,
                dosageMg: dosageMg,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a care protocol threshold in status proposed.
    static func newCareProtocolThreshold(_ code: String, name: String) -> CareProtocolThreshold {
        return CareProtocolThreshold(
            code: code,
            name: name,
            patientRef: "",
            country: "",
            phone: "",
            dosageMg: 0.0,
            ceiling: 0.0,
            status: CareProtocolThresholdStatus.proposed
        )
    }
}
