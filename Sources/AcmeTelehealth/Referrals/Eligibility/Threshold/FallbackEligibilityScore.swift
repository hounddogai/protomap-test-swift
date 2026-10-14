import AcmePlatform
import Foundation

extension Referrals {
    /// Where a fallback eligibility score is in its life cycle.
    enum FallbackEligibilityScoreStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One fallback eligibility score, with what the planners need to act on it.
    final class FallbackEligibilityScore {
        var code: String
        var name: String
        var limit: Int
        var refills: Int
        var visible: Bool
        var graceDays: Int
        var checksum: String
        var category: String
        var clinicianID: String
        var ceiling: Double
        var retries: Int
        var status: FallbackEligibilityScoreStatus

        init(code: String, name: String, limit: Int, refills: Int, visible: Bool, graceDays: Int, checksum: String, category: String, clinicianID: String, ceiling: Double, retries: Int, status: FallbackEligibilityScoreStatus) {
            self.code = code
            self.name = name
            self.limit = limit
            self.refills = refills
            self.visible = visible
            self.graceDays = graceDays
            self.checksum = checksum
            self.category = category
            self.clinicianID = clinicianID
            self.ceiling = ceiling
            self.retries = retries
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FallbackEligibilityScoreStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == FallbackEligibilityScoreStatus.completed || next == FallbackEligibilityScoreStatus.cancelled
            case .completed:
                return next == FallbackEligibilityScoreStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackEligibilityScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback eligibility score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func adjustedLoad() -> Double {
            return ((Double(graceDays) + Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> FallbackEligibilityScore {
            return FallbackEligibilityScore(
                code: code,
                name: name,
                limit: limit,
                refills: refills,
                visible: visible,
                graceDays: graceDays,
                checksum: checksum,
                category: category,
                clinicianID: clinicianID,
                ceiling: ceiling,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a fallback eligibility score in status planned.
    static func newFallbackEligibilityScore(_ code: String, name: String) -> FallbackEligibilityScore {
        return FallbackEligibilityScore(
            code: code,
            name: name,
            limit: 0,
            refills: 0,
            visible: false,
            graceDays: 0,
            checksum: "",
            category: "",
            clinicianID: "",
            ceiling: 0.0,
            retries: 0,
            status: FallbackEligibilityScoreStatus.planned
        )
    }
}
