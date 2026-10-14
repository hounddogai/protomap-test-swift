import AcmePlatform
import Foundation

extension Referrals {
    /// Where a pending slot entry is in its life cycle.
    enum PendingSlotEntryStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A pending slot entry. Its code is unique within a tenant.
    final class PendingSlotEntry {
        var code: String
        var title: String
        var payer: String
        var discount: Double
        var score: Double
        var clinicianID: String
        var category: String
        var source: String
        var region: String
        var procedureCode: String
        var status: PendingSlotEntryStatus

        init(code: String, title: String, payer: String, discount: Double, score: Double, clinicianID: String, category: String, source: String, region: String, procedureCode: String, status: PendingSlotEntryStatus) {
            self.code = code
            self.title = title
            self.payer = payer
            self.discount = discount
            self.score = score
            self.clinicianID = clinicianID
            self.category = category
            self.source = source
            self.region = region
            self.procedureCode = procedureCode
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

        func canMoveTo(_ next: PendingSlotEntryStatus) -> Bool {
            switch status {
            case .proposed:
                return next == PendingSlotEntryStatus.approved
            case .approved:
                return next == PendingSlotEntryStatus.withdrawn
            case .rejected:
                return next == PendingSlotEntryStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingSlotEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending slot entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("pending slot entry") \(code)"
        }

        func effectiveExposure() -> Double {
            return ((score - discount) * 100).rounded() / 100
        }

        func copyValue() -> PendingSlotEntry {
            return PendingSlotEntry(
                code: code,
                title: title,
                payer: payer,
                discount: discount,
                score: score,
                clinicianID: clinicianID,
                category: category,
                source: source,
                region: region,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a pending slot entry in status proposed.
    static func newPendingSlotEntry(_ code: String, title: String) -> PendingSlotEntry {
        return PendingSlotEntry(
            code: code,
            title: title,
            payer: "",
            discount: 0.0,
            score: 0.0,
            clinicianID: "",
            category: "",
            source: "",
            region: "",
            procedureCode: "",
            status: PendingSlotEntryStatus.proposed
        )
    }
}
