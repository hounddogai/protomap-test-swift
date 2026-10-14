import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a tiered claim quota is in its life cycle.
    enum TieredClaimQuotaStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a tiered claim quota and its current status.
    final class TieredClaimQuota {
        var code: String
        var name: String
        var title: String
        var graceDays: Int
        var archived: Bool
        var diagnosisCode: String
        var updatedAt: Int
        var notes: String
        var clinicianID: String
        var status: TieredClaimQuotaStatus

        init(code: String, name: String, title: String, graceDays: Int, archived: Bool, diagnosisCode: String, updatedAt: Int, notes: String, clinicianID: String, status: TieredClaimQuotaStatus) {
            self.code = code
            self.name = name
            self.title = title
            self.graceDays = graceDays
            self.archived = archived
            self.diagnosisCode = diagnosisCode
            self.updatedAt = updatedAt
            self.notes = notes
            self.clinicianID = clinicianID
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

        func canMoveTo(_ next: TieredClaimQuotaStatus) -> Bool {
            switch status {
            case .`open`:
                return next == TieredClaimQuotaStatus.archived
            case .inReview:
                switch next {
                case .archived:
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
                return next == TieredClaimQuotaStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredClaimQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered claim quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("tiered claim quota") \(code)"
        }

        func netExposure() -> Double {
            return ((Double(updatedAt) + Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> TieredClaimQuota {
            return TieredClaimQuota(
                code: code,
                name: name,
                title: title,
                graceDays: graceDays,
                archived: archived,
                diagnosisCode: diagnosisCode,
                updatedAt: updatedAt,
                notes: notes,
                clinicianID: clinicianID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a tiered claim quota in status open.
    static func newTieredClaimQuota(_ code: String, name: String) -> TieredClaimQuota {
        return TieredClaimQuota(
            code: code,
            name: name,
            title: "",
            graceDays: 0,
            archived: false,
            diagnosisCode: "",
            updatedAt: 0,
            notes: "",
            clinicianID: "",
            status: TieredClaimQuotaStatus.`open`
        )
    }
}
