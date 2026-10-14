import AcmePlatform
import Foundation

extension Labs {
    /// Where a regional result reservation is in its life cycle.
    enum RegionalResultReservationStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A regional result reservation as the result team keeps it.
    final class RegionalResultReservation {
        var code: String
        var label: String
        var currency: String
        var retries: Int
        var attributes: [String: String]
        var title: String
        var acuity: Int
        var unit: String
        var status: RegionalResultReservationStatus

        init(code: String, label: String, currency: String, retries: Int, attributes: [String: String], title: String, acuity: Int, unit: String, status: RegionalResultReservationStatus) {
            self.code = code
            self.label = label
            self.currency = currency
            self.retries = retries
            self.attributes = attributes
            self.title = title
            self.acuity = acuity
            self.unit = unit
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

        func canMoveTo(_ next: RegionalResultReservationStatus) -> Bool {
            switch status {
            case .requested:
                return next == RegionalResultReservationStatus.revoked
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == RegionalResultReservationStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalResultReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional result reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
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

        func weightedLoad() -> Double {
            return ((Double(acuity) + Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> RegionalResultReservation {
            return RegionalResultReservation(
                code: code,
                label: label,
                currency: currency,
                retries: retries,
                attributes: attributes,
                title: title,
                acuity: acuity,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a regional result reservation in status requested.
    static func newRegionalResultReservation(_ code: String, label: String) -> RegionalResultReservation {
        return RegionalResultReservation(
            code: code,
            label: label,
            currency: "",
            retries: 0,
            attributes: [:],
            title: "",
            acuity: 0,
            unit: "",
            status: RegionalResultReservationStatus.requested
        )
    }
}
