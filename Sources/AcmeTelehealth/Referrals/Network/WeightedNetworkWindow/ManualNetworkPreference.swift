import AcmePlatform
import Foundation

extension Referrals {
    /// Where a manual network preference is in its life cycle.
    enum ManualNetworkPreferenceStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A manual network preference. Its code is unique within a tenant.
    final class ManualNetworkPreference {
        var code: String
        var title: String
        var ownerID: String
        var country: String
        var source: String
        var limit: Int
        var timezone: String
        var phone: String
        var minimum: Double
        var ceiling: Double
        var currency: String
        var status: ManualNetworkPreferenceStatus

        init(code: String, title: String, ownerID: String, country: String, source: String, limit: Int, timezone: String, phone: String, minimum: Double, ceiling: Double, currency: String, status: ManualNetworkPreferenceStatus) {
            self.code = code
            self.title = title
            self.ownerID = ownerID
            self.country = country
            self.source = source
            self.limit = limit
            self.timezone = timezone
            self.phone = phone
            self.minimum = minimum
            self.ceiling = ceiling
            self.currency = currency
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

        func canMoveTo(_ next: ManualNetworkPreferenceStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == ManualNetworkPreferenceStatus.draining || next == ManualNetworkPreferenceStatus.stopped
            case .draining:
                return next == ManualNetworkPreferenceStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualNetworkPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual network preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("manual network preference") \(code)"
        }

        func weightedLoad() -> Double {
            return ((Double(limit) + ceiling) * 100).rounded() / 100
        }

        func copyValue() -> ManualNetworkPreference {
            return ManualNetworkPreference(
                code: code,
                title: title,
                ownerID: ownerID,
                country: country,
                source: source,
                limit: limit,
                timezone: timezone,
                phone: phone,
                minimum: minimum,
                ceiling: ceiling,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a manual network preference in status idle.
    static func newManualNetworkPreference(_ code: String, title: String) -> ManualNetworkPreference {
        return ManualNetworkPreference(
            code: code,
            title: title,
            ownerID: "",
            country: "",
            source: "",
            limit: 0,
            timezone: "",
            phone: "",
            minimum: 0.0,
            ceiling: 0.0,
            currency: "",
            status: ManualNetworkPreferenceStatus.idle
        )
    }
}
