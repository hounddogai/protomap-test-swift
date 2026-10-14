import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a scheduled census budget is in its life cycle.
    enum ScheduledCensusBudgetStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A scheduled census budget. Its code is unique within a tenant.
    final class ScheduledCensusBudget {
        var code: String
        var name: String
        var active: Bool
        var locale: String
        var maximum: Double
        var allergy: String
        var visible: Bool
        var country: String
        var status: ScheduledCensusBudgetStatus

        init(code: String, name: String, active: Bool, locale: String, maximum: Double, allergy: String, visible: Bool, country: String, status: ScheduledCensusBudgetStatus) {
            self.code = code
            self.name = name
            self.active = active
            self.locale = locale
            self.maximum = maximum
            self.allergy = allergy
            self.visible = visible
            self.country = country
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

        func canMoveTo(_ next: ScheduledCensusBudgetStatus) -> Bool {
            switch status {
            case .new:
                return next == ScheduledCensusBudgetStatus.running || next == ScheduledCensusBudgetStatus.failed
            case .queued:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: ScheduledCensusBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled census budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func measuredValue() -> Double {
            return maximum
        }

        func copyValue() -> ScheduledCensusBudget {
            return ScheduledCensusBudget(
                code: code,
                name: name,
                active: active,
                locale: locale,
                maximum: maximum,
                allergy: allergy,
                visible: visible,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a scheduled census budget in status new.
    static func newScheduledCensusBudget(_ code: String, name: String) -> ScheduledCensusBudget {
        return ScheduledCensusBudget(
            code: code,
            name: name,
            active: false,
            locale: "",
            maximum: 0.0,
            allergy: "",
            visible: false,
            country: "",
            status: ScheduledCensusBudgetStatus.new
        )
    }
}
