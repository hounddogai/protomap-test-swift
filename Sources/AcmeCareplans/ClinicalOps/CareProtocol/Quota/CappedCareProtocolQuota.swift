import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a capped care protocol quota is in its life cycle.
    enum CappedCareProtocolQuotaStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a capped care protocol quota and its current status.
    final class CappedCareProtocolQuota {
        var code: String
        var label: String
        var contactEmail: String
        var discount: Double
        var procedureCode: String
        var updatedAt: Int
        var status: CappedCareProtocolQuotaStatus

        init(code: String, label: String, contactEmail: String, discount: Double, procedureCode: String, updatedAt: Int, status: CappedCareProtocolQuotaStatus) {
            self.code = code
            self.label = label
            self.contactEmail = contactEmail
            self.discount = discount
            self.procedureCode = procedureCode
            self.updatedAt = updatedAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CappedCareProtocolQuotaStatus) -> Bool {
            switch status {
            case .idle:
                return next == CappedCareProtocolQuotaStatus.draining || next == CappedCareProtocolQuotaStatus.stopped
            case .warming:
                return next == CappedCareProtocolQuotaStatus.draining || next == CappedCareProtocolQuotaStatus.stopped
            case .ready:
                return next == CappedCareProtocolQuotaStatus.stopped
            case .draining:
                return next == CappedCareProtocolQuotaStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedCareProtocolQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped care protocol quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func effectiveLoad() -> Double {
            return ((discount + Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> CappedCareProtocolQuota {
            return CappedCareProtocolQuota(
                code: code,
                label: label,
                contactEmail: contactEmail,
                discount: discount,
                procedureCode: procedureCode,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a capped care protocol quota in status idle.
    static func newCappedCareProtocolQuota(_ code: String, label: String) -> CappedCareProtocolQuota {
        return CappedCareProtocolQuota(
            code: code,
            label: label,
            contactEmail: "",
            discount: 0.0,
            procedureCode: "",
            updatedAt: 0,
            status: CappedCareProtocolQuotaStatus.idle
        )
    }
}
