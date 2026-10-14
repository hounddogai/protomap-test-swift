import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a risk score summary is in its life cycle.
    enum RiskScoreSummaryStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a risk score summary and its current status.
    final class RiskScoreSummary {
        var code: String
        var title: String
        var approved: Bool
        var currency: String
        var category: String
        var graceDays: Int
        var visitMinutes: Int
        var windowDays: Int
        var status: RiskScoreSummaryStatus

        init(code: String, title: String, approved: Bool, currency: String, category: String, graceDays: Int, visitMinutes: Int, windowDays: Int, status: RiskScoreSummaryStatus) {
            self.code = code
            self.title = title
            self.approved = approved
            self.currency = currency
            self.category = category
            self.graceDays = graceDays
            self.visitMinutes = visitMinutes
            self.windowDays = windowDays
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

        func canMoveTo(_ next: RiskScoreSummaryStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == RiskScoreSummaryStatus.revoked
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

        func moveTo(_ next: RiskScoreSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("risk score summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func weightedTotal() -> Double {
            return (Double(windowDays) * Double(visitMinutes) * 100).rounded() / 100
        }

        func copyValue() -> RiskScoreSummary {
            return RiskScoreSummary(
                code: code,
                title: title,
                approved: approved,
                currency: currency,
                category: category,
                graceDays: graceDays,
                visitMinutes: visitMinutes,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a risk score summary in status requested.
    static func newRiskScoreSummary(_ code: String, title: String) -> RiskScoreSummary {
        return RiskScoreSummary(
            code: code,
            title: title,
            approved: false,
            currency: "",
            category: "",
            graceDays: 0,
            visitMinutes: 0,
            windowDays: 0,
            status: RiskScoreSummaryStatus.requested
        )
    }
}
