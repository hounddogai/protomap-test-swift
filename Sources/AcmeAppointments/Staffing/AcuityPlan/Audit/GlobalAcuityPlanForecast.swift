import AcmePlatform
import Foundation

extension Staffing {
    /// Where a global acuity plan forecast is in its life cycle.
    enum GlobalAcuityPlanForecastStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A global acuity plan forecast as the acuity plan team keeps it.
    final class GlobalAcuityPlanForecast {
        var code: String
        var label: String
        var phone: String
        var payer: String
        var visitMinutes: Int
        var timezone: String
        var quantity: Int
        var allergy: String
        var minimum: Double
        var locale: String
        var status: GlobalAcuityPlanForecastStatus

        init(code: String, label: String, phone: String, payer: String, visitMinutes: Int, timezone: String, quantity: Int, allergy: String, minimum: Double, locale: String, status: GlobalAcuityPlanForecastStatus) {
            self.code = code
            self.label = label
            self.phone = phone
            self.payer = payer
            self.visitMinutes = visitMinutes
            self.timezone = timezone
            self.quantity = quantity
            self.allergy = allergy
            self.minimum = minimum
            self.locale = locale
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: GlobalAcuityPlanForecastStatus) -> Bool {
            switch status {
            case .idle:
                return next == GlobalAcuityPlanForecastStatus.warming
            case .warming:
                return next == GlobalAcuityPlanForecastStatus.stopped
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: GlobalAcuityPlanForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global acuity plan forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("global acuity plan forecast") \(code)"
        }

        func projectedLoad() -> Double {
            return ((Double(visitMinutes) - minimum) * 100).rounded() / 100
        }

        func copyValue() -> GlobalAcuityPlanForecast {
            return GlobalAcuityPlanForecast(
                code: code,
                label: label,
                phone: phone,
                payer: payer,
                visitMinutes: visitMinutes,
                timezone: timezone,
                quantity: quantity,
                allergy: allergy,
                minimum: minimum,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a global acuity plan forecast in status idle.
    static func newGlobalAcuityPlanForecast(_ code: String, label: String) -> GlobalAcuityPlanForecast {
        return GlobalAcuityPlanForecast(
            code: code,
            label: label,
            phone: "",
            payer: "",
            visitMinutes: 0,
            timezone: "",
            quantity: 0,
            allergy: "",
            minimum: 0.0,
            locale: "",
            status: GlobalAcuityPlanForecastStatus.idle
        )
    }
}
