import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a care gap quota is in its life cycle.
    enum CareGapQuotaStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A care gap quota. Its code is unique within a tenant.
    final class CareGapQuota {
        var code: String
        var title: String
        var clinicianID: String
        var threshold: Double
        var durationMinutes: Int
        var country: String
        var quantity: Int
        var dosageMg: Double
        var archived: Bool
        var minimum: Double
        var status: CareGapQuotaStatus

        init(code: String, title: String, clinicianID: String, threshold: Double, durationMinutes: Int, country: String, quantity: Int, dosageMg: Double, archived: Bool, minimum: Double, status: CareGapQuotaStatus) {
            self.code = code
            self.title = title
            self.clinicianID = clinicianID
            self.threshold = threshold
            self.durationMinutes = durationMinutes
            self.country = country
            self.quantity = quantity
            self.dosageMg = dosageMg
            self.archived = archived
            self.minimum = minimum
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

        func canMoveTo(_ next: CareGapQuotaStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == CareGapQuotaStatus.resolved
            case .resolved:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == CareGapQuotaStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareGapQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care gap quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("care gap quota") \(code)"
        }

        func weightedTotal() -> Double {
            return (Double(durationMinutes) * minimum * 100).rounded() / 100
        }

        func copyValue() -> CareGapQuota {
            return CareGapQuota(
                code: code,
                title: title,
                clinicianID: clinicianID,
                threshold: threshold,
                durationMinutes: durationMinutes,
                country: country,
                quantity: quantity,
                dosageMg: dosageMg,
                archived: archived,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a care gap quota in status open.
    static func newCareGapQuota(_ code: String, title: String) -> CareGapQuota {
        return CareGapQuota(
            code: code,
            title: title,
            clinicianID: "",
            threshold: 0.0,
            durationMinutes: 0,
            country: "",
            quantity: 0,
            dosageMg: 0.0,
            archived: false,
            minimum: 0.0,
            status: CareGapQuotaStatus.`open`
        )
    }
}
