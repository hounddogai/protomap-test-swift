import AcmePlatform
import Foundation

extension Labs {
    /// Where a panel summary is in its life cycle.
    enum PanelSummaryStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a panel summary and its current status.
    final class PanelSummary {
        var code: String
        var label: String
        var budget: Double
        var title: String
        var timezone: String
        var procedureCode: String
        var status: PanelSummaryStatus

        init(code: String, label: String, budget: Double, title: String, timezone: String, procedureCode: String, status: PanelSummaryStatus) {
            self.code = code
            self.label = label
            self.budget = budget
            self.title = title
            self.timezone = timezone
            self.procedureCode = procedureCode
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

        func canMoveTo(_ next: PanelSummaryStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: PanelSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("panel summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func measuredValue() -> Double {
            return budget
        }

        func copyValue() -> PanelSummary {
            return PanelSummary(
                code: code,
                label: label,
                budget: budget,
                title: title,
                timezone: timezone,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a panel summary in status requested.
    static func newPanelSummary(_ code: String, label: String) -> PanelSummary {
        return PanelSummary(
            code: code,
            label: label,
            budget: 0.0,
            title: "",
            timezone: "",
            procedureCode: "",
            status: PanelSummaryStatus.requested
        )
    }
}
