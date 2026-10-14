import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a seasonal handoff budget is in its life cycle.
    enum SeasonalHandoffBudgetStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A seasonal handoff budget. Its code is unique within a tenant.
    final class SeasonalHandoffBudget {
        var code: String
        var name: String
        var windowDays: Int
        var approved: Bool
        var ownerID: String
        var timezone: String
        var limit: Int
        var phone: String
        var procedureCode: String
        var threshold: Double
        var status: SeasonalHandoffBudgetStatus

        init(code: String, name: String, windowDays: Int, approved: Bool, ownerID: String, timezone: String, limit: Int, phone: String, procedureCode: String, threshold: Double, status: SeasonalHandoffBudgetStatus) {
            self.code = code
            self.name = name
            self.windowDays = windowDays
            self.approved = approved
            self.ownerID = ownerID
            self.timezone = timezone
            self.limit = limit
            self.phone = phone
            self.procedureCode = procedureCode
            self.threshold = threshold
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

        func canMoveTo(_ next: SeasonalHandoffBudgetStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == SeasonalHandoffBudgetStatus.revoked || next == SeasonalHandoffBudgetStatus.expired
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

        func moveTo(_ next: SeasonalHandoffBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal handoff budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func effectiveValue() -> Double {
            return ((threshold + Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalHandoffBudget {
            return SeasonalHandoffBudget(
                code: code,
                name: name,
                windowDays: windowDays,
                approved: approved,
                ownerID: ownerID,
                timezone: timezone,
                limit: limit,
                phone: phone,
                procedureCode: procedureCode,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a seasonal handoff budget in status requested.
    static func newSeasonalHandoffBudget(_ code: String, name: String) -> SeasonalHandoffBudget {
        return SeasonalHandoffBudget(
            code: code,
            name: name,
            windowDays: 0,
            approved: false,
            ownerID: "",
            timezone: "",
            limit: 0,
            phone: "",
            procedureCode: "",
            threshold: 0.0,
            status: SeasonalHandoffBudgetStatus.requested
        )
    }
}
