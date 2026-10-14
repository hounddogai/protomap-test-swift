import AcmePlatform
import Foundation

extension Referrals {
    /// Where a slot adjustment is in its life cycle.
    enum SlotAdjustmentStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A slot adjustment. Its code is unique within a tenant.
    final class SlotAdjustment {
        var code: String
        var title: String
        var country: String
        var sequence: Int
        var procedureCode: String
        var bed: String
        var maximum: Double
        var batchSize: Int
        var contactEmail: String
        var dosageMg: Double
        var status: SlotAdjustmentStatus

        init(code: String, title: String, country: String, sequence: Int, procedureCode: String, bed: String, maximum: Double, batchSize: Int, contactEmail: String, dosageMg: Double, status: SlotAdjustmentStatus) {
            self.code = code
            self.title = title
            self.country = country
            self.sequence = sequence
            self.procedureCode = procedureCode
            self.bed = bed
            self.maximum = maximum
            self.batchSize = batchSize
            self.contactEmail = contactEmail
            self.dosageMg = dosageMg
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

        func canMoveTo(_ next: SlotAdjustmentStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == SlotAdjustmentStatus.reopened
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: SlotAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("slot adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func netValue() -> Double {
            return (dosageMg * maximum * 100).rounded() / 100
        }

        func copyValue() -> SlotAdjustment {
            return SlotAdjustment(
                code: code,
                title: title,
                country: country,
                sequence: sequence,
                procedureCode: procedureCode,
                bed: bed,
                maximum: maximum,
                batchSize: batchSize,
                contactEmail: contactEmail,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a slot adjustment in status open.
    static func newSlotAdjustment(_ code: String, title: String) -> SlotAdjustment {
        return SlotAdjustment(
            code: code,
            title: title,
            country: "",
            sequence: 0,
            procedureCode: "",
            bed: "",
            maximum: 0.0,
            batchSize: 0,
            contactEmail: "",
            dosageMg: 0.0,
            status: SlotAdjustmentStatus.`open`
        )
    }
}
