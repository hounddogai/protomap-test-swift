import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a capped remittance audit is in its life cycle.
    enum CappedRemittanceAuditStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A capped remittance audit as the remittance team keeps it.
    final class CappedRemittanceAudit {
        var code: String
        var label: String
        var procedureCode: String
        var visible: Bool
        var amount: Double
        var title: String
        var batchSize: Int
        var ward: String
        var status: CappedRemittanceAuditStatus

        init(code: String, label: String, procedureCode: String, visible: Bool, amount: Double, title: String, batchSize: Int, ward: String, status: CappedRemittanceAuditStatus) {
            self.code = code
            self.label = label
            self.procedureCode = procedureCode
            self.visible = visible
            self.amount = amount
            self.title = title
            self.batchSize = batchSize
            self.ward = ward
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

        func canMoveTo(_ next: CappedRemittanceAuditStatus) -> Bool {
            switch status {
            case .requested:
                return next == CappedRemittanceAuditStatus.granted || next == CappedRemittanceAuditStatus.expired
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: CappedRemittanceAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped remittance audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("capped remittance audit") \(code)"
        }

        func adjustedExposure() -> Double {
            return (Double(batchSize) * amount * 100).rounded() / 100
        }

        func copyValue() -> CappedRemittanceAudit {
            return CappedRemittanceAudit(
                code: code,
                label: label,
                procedureCode: procedureCode,
                visible: visible,
                amount: amount,
                title: title,
                batchSize: batchSize,
                ward: ward,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a capped remittance audit in status requested.
    static func newCappedRemittanceAudit(_ code: String, label: String) -> CappedRemittanceAudit {
        return CappedRemittanceAudit(
            code: code,
            label: label,
            procedureCode: "",
            visible: false,
            amount: 0.0,
            title: "",
            batchSize: 0,
            ward: "",
            status: CappedRemittanceAuditStatus.requested
        )
    }
}
