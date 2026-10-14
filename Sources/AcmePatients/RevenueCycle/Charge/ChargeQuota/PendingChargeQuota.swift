import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a pending charge quota is in its life cycle.
    enum PendingChargeQuotaStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One pending charge quota, with what the planners need to act on it.
    final class PendingChargeQuota {
        var code: String
        var title: String
        var discount: Double
        var summary: String
        var updatedAt: Int
        var diagnosisCode: String
        var startsAt: Int
        var category: String
        var sequence: Int
        var allergy: String
        var createdAt: Int
        var status: PendingChargeQuotaStatus

        init(code: String, title: String, discount: Double, summary: String, updatedAt: Int, diagnosisCode: String, startsAt: Int, category: String, sequence: Int, allergy: String, createdAt: Int, status: PendingChargeQuotaStatus) {
            self.code = code
            self.title = title
            self.discount = discount
            self.summary = summary
            self.updatedAt = updatedAt
            self.diagnosisCode = diagnosisCode
            self.startsAt = startsAt
            self.category = category
            self.sequence = sequence
            self.allergy = allergy
            self.createdAt = createdAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PendingChargeQuotaStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == PendingChargeQuotaStatus.failed
            case .running:
                return next == PendingChargeQuotaStatus.done || next == PendingChargeQuotaStatus.failed
            case .done:
                return next == PendingChargeQuotaStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingChargeQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending charge quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func weightedTotal() -> Double {
            return ((Double(startsAt) - Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> PendingChargeQuota {
            return PendingChargeQuota(
                code: code,
                title: title,
                discount: discount,
                summary: summary,
                updatedAt: updatedAt,
                diagnosisCode: diagnosisCode,
                startsAt: startsAt,
                category: category,
                sequence: sequence,
                allergy: allergy,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a pending charge quota in status new.
    static func newPendingChargeQuota(_ code: String, title: String) -> PendingChargeQuota {
        return PendingChargeQuota(
            code: code,
            title: title,
            discount: 0.0,
            summary: "",
            updatedAt: 0,
            diagnosisCode: "",
            startsAt: 0,
            category: "",
            sequence: 0,
            allergy: "",
            createdAt: 0,
            status: PendingChargeQuotaStatus.new
        )
    }
}
