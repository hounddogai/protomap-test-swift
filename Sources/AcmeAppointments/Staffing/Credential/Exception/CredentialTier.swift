import AcmePlatform
import Foundation

extension Staffing {
    /// Where a credential tier is in its life cycle.
    enum CredentialTierStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a credential tier and its current status.
    final class CredentialTier {
        var code: String
        var name: String
        var retries: Int
        var minimum: Double
        var startsAt: Int
        var attributes: [String: String]
        var timezone: String
        var maximum: Double
        var ward: String
        var status: CredentialTierStatus

        init(code: String, name: String, retries: Int, minimum: Double, startsAt: Int, attributes: [String: String], timezone: String, maximum: Double, ward: String, status: CredentialTierStatus) {
            self.code = code
            self.name = name
            self.retries = retries
            self.minimum = minimum
            self.startsAt = startsAt
            self.attributes = attributes
            self.timezone = timezone
            self.maximum = maximum
            self.ward = ward
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

        func canMoveTo(_ next: CredentialTierStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == CredentialTierStatus.running || next == CredentialTierStatus.done
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == CredentialTierStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CredentialTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("credential tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
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

        func netLoad() -> Double {
            return ((Double(startsAt) + maximum) * 100).rounded() / 100
        }

        func copyValue() -> CredentialTier {
            return CredentialTier(
                code: code,
                name: name,
                retries: retries,
                minimum: minimum,
                startsAt: startsAt,
                attributes: attributes,
                timezone: timezone,
                maximum: maximum,
                ward: ward,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a credential tier in status new.
    static func newCredentialTier(_ code: String, name: String) -> CredentialTier {
        return CredentialTier(
            code: code,
            name: name,
            retries: 0,
            minimum: 0.0,
            startsAt: 0,
            attributes: [:],
            timezone: "",
            maximum: 0.0,
            ward: "",
            status: CredentialTierStatus.new
        )
    }
}
