import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a seasonal care gap assignment is in its life cycle.
    enum SeasonalCareGapAssignmentStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One seasonal care gap assignment, with what the planners need to act on it.
    final class SeasonalCareGapAssignment {
        var code: String
        var name: String
        var amount: Double
        var acuity: Int
        var expiresAt: Int
        var ceiling: Double
        var status: SeasonalCareGapAssignmentStatus

        init(code: String, name: String, amount: Double, acuity: Int, expiresAt: Int, ceiling: Double, status: SeasonalCareGapAssignmentStatus) {
            self.code = code
            self.name = name
            self.amount = amount
            self.acuity = acuity
            self.expiresAt = expiresAt
            self.ceiling = ceiling
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

        func canMoveTo(_ next: SeasonalCareGapAssignmentStatus) -> Bool {
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
                return next == SeasonalCareGapAssignmentStatus.reopened
            case .resolved:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == SeasonalCareGapAssignmentStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalCareGapAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal care gap assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("seasonal care gap assignment") \(code)"
        }

        func projectedExposure() -> Double {
            return ((ceiling + amount) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalCareGapAssignment {
            return SeasonalCareGapAssignment(
                code: code,
                name: name,
                amount: amount,
                acuity: acuity,
                expiresAt: expiresAt,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a seasonal care gap assignment in status open.
    static func newSeasonalCareGapAssignment(_ code: String, name: String) -> SeasonalCareGapAssignment {
        return SeasonalCareGapAssignment(
            code: code,
            name: name,
            amount: 0.0,
            acuity: 0,
            expiresAt: 0,
            ceiling: 0.0,
            status: SeasonalCareGapAssignmentStatus.`open`
        )
    }
}
