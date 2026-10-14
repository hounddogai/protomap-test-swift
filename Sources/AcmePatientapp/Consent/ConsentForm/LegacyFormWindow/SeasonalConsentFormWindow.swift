import AcmePlatform
import Foundation

extension Consent {
    /// Where a seasonal consent form window is in its life cycle.
    enum SeasonalConsentFormWindowStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A seasonal consent form window as the consent form team keeps it.
    final class SeasonalConsentFormWindow {
        var code: String
        var title: String
        var priority: Int
        var name: String
        var limit: Int
        var capacity: Int
        var payer: String
        var approved: Bool
        var contactEmail: String
        var ward: String
        var floorValue: Double
        var status: SeasonalConsentFormWindowStatus

        init(code: String, title: String, priority: Int, name: String, limit: Int, capacity: Int, payer: String, approved: Bool, contactEmail: String, ward: String, floorValue: Double, status: SeasonalConsentFormWindowStatus) {
            self.code = code
            self.title = title
            self.priority = priority
            self.name = name
            self.limit = limit
            self.capacity = capacity
            self.payer = payer
            self.approved = approved
            self.contactEmail = contactEmail
            self.ward = ward
            self.floorValue = floorValue
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

        func canMoveTo(_ next: SeasonalConsentFormWindowStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted:
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
                return next == SeasonalConsentFormWindowStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalConsentFormWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal consent form window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("seasonal consent form window") \(code)"
        }

        func projectedVolume() -> Double {
            return ((Double(limit) - Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalConsentFormWindow {
            return SeasonalConsentFormWindow(
                code: code,
                title: title,
                priority: priority,
                name: name,
                limit: limit,
                capacity: capacity,
                payer: payer,
                approved: approved,
                contactEmail: contactEmail,
                ward: ward,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a seasonal consent form window in status requested.
    static func newSeasonalConsentFormWindow(_ code: String, title: String) -> SeasonalConsentFormWindow {
        return SeasonalConsentFormWindow(
            code: code,
            title: title,
            priority: 0,
            name: "",
            limit: 0,
            capacity: 0,
            payer: "",
            approved: false,
            contactEmail: "",
            ward: "",
            floorValue: 0.0,
            status: SeasonalConsentFormWindowStatus.requested
        )
    }
}
