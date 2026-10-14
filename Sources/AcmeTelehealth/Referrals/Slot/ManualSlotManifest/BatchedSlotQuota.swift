import AcmePlatform
import Foundation

extension Referrals {
    /// Where a batched slot quota is in its life cycle.
    enum BatchedSlotQuotaStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A batched slot quota as the slot team keeps it.
    final class BatchedSlotQuota {
        var code: String
        var title: String
        var specialty: String
        var country: String
        var diagnosisCode: String
        var tags: [String]
        var score: Double
        var status: BatchedSlotQuotaStatus

        init(code: String, title: String, specialty: String, country: String, diagnosisCode: String, tags: [String], score: Double, status: BatchedSlotQuotaStatus) {
            self.code = code
            self.title = title
            self.specialty = specialty
            self.country = country
            self.diagnosisCode = diagnosisCode
            self.tags = tags
            self.score = score
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

        func canMoveTo(_ next: BatchedSlotQuotaStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == BatchedSlotQuotaStatus.rejected || next == BatchedSlotQuotaStatus.withdrawn
            case .rejected:
                return next == BatchedSlotQuotaStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedSlotQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched slot quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> BatchedSlotQuota {
            return BatchedSlotQuota(
                code: code,
                title: title,
                specialty: specialty,
                country: country,
                diagnosisCode: diagnosisCode,
                tags: tags,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a batched slot quota in status proposed.
    static func newBatchedSlotQuota(_ code: String, title: String) -> BatchedSlotQuota {
        return BatchedSlotQuota(
            code: code,
            title: title,
            specialty: "",
            country: "",
            diagnosisCode: "",
            tags: [],
            score: 0.0,
            status: BatchedSlotQuotaStatus.proposed
        )
    }
}
