import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a capped charge estimate is in its life cycle.
    enum CappedChargeEstimateStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A capped charge estimate. Its code is unique within a tenant.
    final class CappedChargeEstimate {
        var code: String
        var title: String
        var allergy: String
        var revision: Int
        var ownerID: String
        var durationMinutes: Int
        var facility: String
        var limit: Int
        var endsAt: Int
        var acuity: Int
        var clinicianID: String
        var status: CappedChargeEstimateStatus

        init(code: String, title: String, allergy: String, revision: Int, ownerID: String, durationMinutes: Int, facility: String, limit: Int, endsAt: Int, acuity: Int, clinicianID: String, status: CappedChargeEstimateStatus) {
            self.code = code
            self.title = title
            self.allergy = allergy
            self.revision = revision
            self.ownerID = ownerID
            self.durationMinutes = durationMinutes
            self.facility = facility
            self.limit = limit
            self.endsAt = endsAt
            self.acuity = acuity
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

        func canMoveTo(_ next: CappedChargeEstimateStatus) -> Bool {
            switch status {
            case .`open`:
                return next == CappedChargeEstimateStatus.reopened
            case .inReview:
                return next == CappedChargeEstimateStatus.resolved
            case .resolved:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: CappedChargeEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped charge estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\("capped charge estimate") \(code)"
        }

        func adjustedLoad() -> Double {
            return ((Double(endsAt) - Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> CappedChargeEstimate {
            return CappedChargeEstimate(
                code: code,
                title: title,
                allergy: allergy,
                revision: revision,
                ownerID: ownerID,
                durationMinutes: durationMinutes,
                facility: facility,
                limit: limit,
                endsAt: endsAt,
                acuity: acuity,
                clinicianID: clinicianID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a capped charge estimate in status open.
    static func newCappedChargeEstimate(_ code: String, title: String) -> CappedChargeEstimate {
        return CappedChargeEstimate(
            code: code,
            title: title,
            allergy: "",
            revision: 0,
            ownerID: "",
            durationMinutes: 0,
            facility: "",
            limit: 0,
            endsAt: 0,
            acuity: 0,
            clinicianID: "",
            status: CappedChargeEstimateStatus.`open`
        )
    }
}
