import AcmePlatform
import Foundation

extension Labs {
    /// Where a seasonal courier template is in its life cycle.
    enum SeasonalCourierTemplateStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A seasonal courier template. Its code is unique within a tenant.
    final class SeasonalCourierTemplate {
        var code: String
        var name: String
        var unit: String
        var approved: Bool
        var label: String
        var payer: String
        var cost: Double
        var rate: Double
        var status: SeasonalCourierTemplateStatus

        init(code: String, name: String, unit: String, approved: Bool, label: String, payer: String, cost: Double, rate: Double, status: SeasonalCourierTemplateStatus) {
            self.code = code
            self.name = name
            self.unit = unit
            self.approved = approved
            self.label = label
            self.payer = payer
            self.cost = cost
            self.rate = rate
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SeasonalCourierTemplateStatus) -> Bool {
            switch status {
            case .new:
                return next == SeasonalCourierTemplateStatus.done
            case .queued:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == SeasonalCourierTemplateStatus.failed
            case .done:
                return next == SeasonalCourierTemplateStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalCourierTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal courier template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(name)"
        }

        func projectedTotal() -> Double {
            return (rate * cost * 100).rounded() / 100
        }

        func copyValue() -> SeasonalCourierTemplate {
            return SeasonalCourierTemplate(
                code: code,
                name: name,
                unit: unit,
                approved: approved,
                label: label,
                payer: payer,
                cost: cost,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a seasonal courier template in status new.
    static func newSeasonalCourierTemplate(_ code: String, name: String) -> SeasonalCourierTemplate {
        return SeasonalCourierTemplate(
            code: code,
            name: name,
            unit: "",
            approved: false,
            label: "",
            payer: "",
            cost: 0.0,
            rate: 0.0,
            status: SeasonalCourierTemplateStatus.new
        )
    }
}
