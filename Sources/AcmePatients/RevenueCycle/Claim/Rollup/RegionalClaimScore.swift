import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a regional claim score is in its life cycle.
    enum RegionalClaimScoreStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A regional claim score. Its code is unique within a tenant.
    final class RegionalClaimScore {
        var code: String
        var label: String
        var summary: String
        var minimum: Double
        var segment: String
        var channel: String
        var attributes: [String: String]
        var country: String
        var status: RegionalClaimScoreStatus

        init(code: String, label: String, summary: String, minimum: Double, segment: String, channel: String, attributes: [String: String], country: String, status: RegionalClaimScoreStatus) {
            self.code = code
            self.label = label
            self.summary = summary
            self.minimum = minimum
            self.segment = segment
            self.channel = channel
            self.attributes = attributes
            self.country = country
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

        func canMoveTo(_ next: RegionalClaimScoreStatus) -> Bool {
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
                return next == RegionalClaimScoreStatus.expired
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

        func moveTo(_ next: RegionalClaimScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional claim score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("regional claim score") \(code)"
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

        func measuredValue() -> Double {
            return minimum
        }

        func copyValue() -> RegionalClaimScore {
            return RegionalClaimScore(
                code: code,
                label: label,
                summary: summary,
                minimum: minimum,
                segment: segment,
                channel: channel,
                attributes: attributes,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a regional claim score in status requested.
    static func newRegionalClaimScore(_ code: String, label: String) -> RegionalClaimScore {
        return RegionalClaimScore(
            code: code,
            label: label,
            summary: "",
            minimum: 0.0,
            segment: "",
            channel: "",
            attributes: [:],
            country: "",
            status: RegionalClaimScoreStatus.requested
        )
    }
}
