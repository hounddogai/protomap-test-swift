import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a risk score estimate is in its life cycle.
    enum RiskScoreEstimateStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A risk score estimate as the risk score team keeps it.
    final class RiskScoreEstimate {
        var code: String
        var title: String
        var notes: String
        var approved: Bool
        var ownerID: String
        var margin: Double
        var revision: Int
        var durationMinutes: Int
        var facility: String
        var windowDays: Int
        var timezone: String
        var status: RiskScoreEstimateStatus

        init(code: String, title: String, notes: String, approved: Bool, ownerID: String, margin: Double, revision: Int, durationMinutes: Int, facility: String, windowDays: Int, timezone: String, status: RiskScoreEstimateStatus) {
            self.code = code
            self.title = title
            self.notes = notes
            self.approved = approved
            self.ownerID = ownerID
            self.margin = margin
            self.revision = revision
            self.durationMinutes = durationMinutes
            self.facility = facility
            self.windowDays = windowDays
            self.timezone = timezone
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

        func canMoveTo(_ next: RiskScoreEstimateStatus) -> Bool {
            switch status {
            case .requested:
                return next == RiskScoreEstimateStatus.expired
            case .granted:
                return next == RiskScoreEstimateStatus.revoked || next == RiskScoreEstimateStatus.expired
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

        func moveTo(_ next: RiskScoreEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("risk score estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func effectiveTotal() -> Double {
            return (margin * Double(durationMinutes) * 100).rounded() / 100
        }

        func copyValue() -> RiskScoreEstimate {
            return RiskScoreEstimate(
                code: code,
                title: title,
                notes: notes,
                approved: approved,
                ownerID: ownerID,
                margin: margin,
                revision: revision,
                durationMinutes: durationMinutes,
                facility: facility,
                windowDays: windowDays,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a risk score estimate in status requested.
    static func newRiskScoreEstimate(_ code: String, title: String) -> RiskScoreEstimate {
        return RiskScoreEstimate(
            code: code,
            title: title,
            notes: "",
            approved: false,
            ownerID: "",
            margin: 0.0,
            revision: 0,
            durationMinutes: 0,
            facility: "",
            windowDays: 0,
            timezone: "",
            status: RiskScoreEstimateStatus.requested
        )
    }
}
