import AcmePlatform
import Foundation

extension Referrals {
    /// Where a eligibility estimate is in its life cycle.
    enum EligibilityEstimateStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a eligibility estimate and its current status.
    final class EligibilityEstimate {
        var code: String
        var title: String
        var segment: String
        var threshold: Double
        var archived: Bool
        var ratio: Double
        var encounterID: String
        var copay: Double
        var status: EligibilityEstimateStatus

        init(code: String, title: String, segment: String, threshold: Double, archived: Bool, ratio: Double, encounterID: String, copay: Double, status: EligibilityEstimateStatus) {
            self.code = code
            self.title = title
            self.segment = segment
            self.threshold = threshold
            self.archived = archived
            self.ratio = ratio
            self.encounterID = encounterID
            self.copay = copay
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

        func canMoveTo(_ next: EligibilityEstimateStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == EligibilityEstimateStatus.revoked
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

        func moveTo(_ next: EligibilityEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("eligibility estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func netLoad() -> Double {
            return ((threshold - copay) * 100).rounded() / 100
        }

        func copyValue() -> EligibilityEstimate {
            return EligibilityEstimate(
                code: code,
                title: title,
                segment: segment,
                threshold: threshold,
                archived: archived,
                ratio: ratio,
                encounterID: encounterID,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a eligibility estimate in status requested.
    static func newEligibilityEstimate(_ code: String, title: String) -> EligibilityEstimate {
        return EligibilityEstimate(
            code: code,
            title: title,
            segment: "",
            threshold: 0.0,
            archived: false,
            ratio: 0.0,
            encounterID: "",
            copay: 0.0,
            status: EligibilityEstimateStatus.requested
        )
    }
}
