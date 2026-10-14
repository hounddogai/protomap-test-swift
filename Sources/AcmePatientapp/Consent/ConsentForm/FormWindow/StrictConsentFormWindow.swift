import AcmePlatform
import Foundation

extension Consent {
    /// Where a strict consent form window is in its life cycle.
    enum StrictConsentFormWindowStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One strict consent form window, with what the planners need to act on it.
    final class StrictConsentFormWindow {
        var code: String
        var name: String
        var segment: String
        var floorValue: Double
        var graceDays: Int
        var expiresAt: Int
        var quantity: Int
        var clinicianID: String
        var locale: String
        var endsAt: Int
        var status: StrictConsentFormWindowStatus

        init(code: String, name: String, segment: String, floorValue: Double, graceDays: Int, expiresAt: Int, quantity: Int, clinicianID: String, locale: String, endsAt: Int, status: StrictConsentFormWindowStatus) {
            self.code = code
            self.name = name
            self.segment = segment
            self.floorValue = floorValue
            self.graceDays = graceDays
            self.expiresAt = expiresAt
            self.quantity = quantity
            self.clinicianID = clinicianID
            self.locale = locale
            self.endsAt = endsAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: StrictConsentFormWindowStatus) -> Bool {
            switch status {
            case .created:
                return next == StrictConsentFormWindowStatus.published
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: StrictConsentFormWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict consent form window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func weightedVolume() -> Double {
            return (Double(quantity) * Double(endsAt) * 100).rounded() / 100
        }

        func copyValue() -> StrictConsentFormWindow {
            return StrictConsentFormWindow(
                code: code,
                name: name,
                segment: segment,
                floorValue: floorValue,
                graceDays: graceDays,
                expiresAt: expiresAt,
                quantity: quantity,
                clinicianID: clinicianID,
                locale: locale,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a strict consent form window in status created.
    static func newStrictConsentFormWindow(_ code: String, name: String) -> StrictConsentFormWindow {
        return StrictConsentFormWindow(
            code: code,
            name: name,
            segment: "",
            floorValue: 0.0,
            graceDays: 0,
            expiresAt: 0,
            quantity: 0,
            clinicianID: "",
            locale: "",
            endsAt: 0,
            status: StrictConsentFormWindowStatus.created
        )
    }
}
