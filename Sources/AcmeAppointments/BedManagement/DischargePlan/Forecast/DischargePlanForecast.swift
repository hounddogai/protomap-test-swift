import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a discharge plan forecast is in its life cycle.
    enum DischargePlanForecastStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A discharge plan forecast. Its code is unique within a tenant.
    final class DischargePlanForecast {
        var code: String
        var name: String
        var notes: String
        var locale: String
        var country: String
        var margin: Double
        var discount: Double
        var attributes: [String: String]
        var version: Int
        var status: DischargePlanForecastStatus

        init(code: String, name: String, notes: String, locale: String, country: String, margin: Double, discount: Double, attributes: [String: String], version: Int, status: DischargePlanForecastStatus) {
            self.code = code
            self.name = name
            self.notes = notes
            self.locale = locale
            self.country = country
            self.margin = margin
            self.discount = discount
            self.attributes = attributes
            self.version = version
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DischargePlanForecastStatus) -> Bool {
            switch status {
            case .draft:
                return next == DischargePlanForecastStatus.active || next == DischargePlanForecastStatus.suspended
            case .pending:
                return next == DischargePlanForecastStatus.active || next == DischargePlanForecastStatus.closed
            case .active:
                return next == DischargePlanForecastStatus.suspended || next == DischargePlanForecastStatus.closed
            case .suspended:
                return next == DischargePlanForecastStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DischargePlanForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("discharge plan forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\("discharge plan forecast") \(code)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func weightedVolume() -> Double {
            return ((Double(version) + margin) * 100).rounded() / 100
        }

        func copyValue() -> DischargePlanForecast {
            return DischargePlanForecast(
                code: code,
                name: name,
                notes: notes,
                locale: locale,
                country: country,
                margin: margin,
                discount: discount,
                attributes: attributes,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a discharge plan forecast in status draft.
    static func newDischargePlanForecast(_ code: String, name: String) -> DischargePlanForecast {
        return DischargePlanForecast(
            code: code,
            name: name,
            notes: "",
            locale: "",
            country: "",
            margin: 0.0,
            discount: 0.0,
            attributes: [:],
            version: 0,
            status: DischargePlanForecastStatus.draft
        )
    }
}
