import AcmePlatform
import Foundation

extension Referrals {
    /// Where a follow up estimate is in its life cycle.
    enum FollowUpEstimateStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One follow up estimate, with what the planners need to act on it.
    final class FollowUpEstimate {
        var code: String
        var label: String
        var allergy: String
        var ownerID: String
        var minimum: Double
        var threshold: Double
        var updatedAt: Int
        var visible: Bool
        var pinned: Bool
        var expiresAt: Int
        var windowDays: Int
        var status: FollowUpEstimateStatus

        init(code: String, label: String, allergy: String, ownerID: String, minimum: Double, threshold: Double, updatedAt: Int, visible: Bool, pinned: Bool, expiresAt: Int, windowDays: Int, status: FollowUpEstimateStatus) {
            self.code = code
            self.label = label
            self.allergy = allergy
            self.ownerID = ownerID
            self.minimum = minimum
            self.threshold = threshold
            self.updatedAt = updatedAt
            self.visible = visible
            self.pinned = pinned
            self.expiresAt = expiresAt
            self.windowDays = windowDays
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

        func canMoveTo(_ next: FollowUpEstimateStatus) -> Bool {
            switch status {
            case .planned:
                return next == FollowUpEstimateStatus.completed || next == FollowUpEstimateStatus.cancelled
            case .scheduled:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: FollowUpEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("follow up estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func projectedTotal() -> Double {
            return (threshold * Double(updatedAt) * 100).rounded() / 100
        }

        func copyValue() -> FollowUpEstimate {
            return FollowUpEstimate(
                code: code,
                label: label,
                allergy: allergy,
                ownerID: ownerID,
                minimum: minimum,
                threshold: threshold,
                updatedAt: updatedAt,
                visible: visible,
                pinned: pinned,
                expiresAt: expiresAt,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a follow up estimate in status planned.
    static func newFollowUpEstimate(_ code: String, label: String) -> FollowUpEstimate {
        return FollowUpEstimate(
            code: code,
            label: label,
            allergy: "",
            ownerID: "",
            minimum: 0.0,
            threshold: 0.0,
            updatedAt: 0,
            visible: false,
            pinned: false,
            expiresAt: 0,
            windowDays: 0,
            status: FollowUpEstimateStatus.planned
        )
    }
}
