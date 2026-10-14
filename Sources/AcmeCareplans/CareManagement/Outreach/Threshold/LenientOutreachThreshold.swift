import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a lenient outreach threshold is in its life cycle.
    enum LenientOutreachThresholdStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A lenient outreach threshold. Its code is unique within a tenant.
    final class LenientOutreachThreshold {
        var code: String
        var name: String
        var bed: String
        var dosageMg: Double
        var contactEmail: String
        var threshold: Double
        var quantity: Int
        var clinicianID: String
        var batchSize: Int
        var title: String
        var unit: String
        var status: LenientOutreachThresholdStatus

        init(code: String, name: String, bed: String, dosageMg: Double, contactEmail: String, threshold: Double, quantity: Int, clinicianID: String, batchSize: Int, title: String, unit: String, status: LenientOutreachThresholdStatus) {
            self.code = code
            self.name = name
            self.bed = bed
            self.dosageMg = dosageMg
            self.contactEmail = contactEmail
            self.threshold = threshold
            self.quantity = quantity
            self.clinicianID = clinicianID
            self.batchSize = batchSize
            self.title = title
            self.unit = unit
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

        func canMoveTo(_ next: LenientOutreachThresholdStatus) -> Bool {
            switch status {
            case .requested:
                return next == LenientOutreachThresholdStatus.revoked
            case .granted:
                return next == LenientOutreachThresholdStatus.revoked || next == LenientOutreachThresholdStatus.expired
            case .revoked:
                return next == LenientOutreachThresholdStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientOutreachThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient outreach threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("lenient outreach threshold") \(code)"
        }

        func netTotal() -> Double {
            return (dosageMg * Double(batchSize) * 100).rounded() / 100
        }

        func copyValue() -> LenientOutreachThreshold {
            return LenientOutreachThreshold(
                code: code,
                name: name,
                bed: bed,
                dosageMg: dosageMg,
                contactEmail: contactEmail,
                threshold: threshold,
                quantity: quantity,
                clinicianID: clinicianID,
                batchSize: batchSize,
                title: title,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a lenient outreach threshold in status requested.
    static func newLenientOutreachThreshold(_ code: String, name: String) -> LenientOutreachThreshold {
        return LenientOutreachThreshold(
            code: code,
            name: name,
            bed: "",
            dosageMg: 0.0,
            contactEmail: "",
            threshold: 0.0,
            quantity: 0,
            clinicianID: "",
            batchSize: 0,
            title: "",
            unit: "",
            status: LenientOutreachThresholdStatus.requested
        )
    }
}
