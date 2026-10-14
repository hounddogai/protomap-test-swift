import AcmePlatform
import Foundation

extension Consent {
    /// Where a consent form preference is in its life cycle.
    enum ConsentFormPreferenceStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A consent form preference as the consent form team keeps it.
    final class ConsentFormPreference {
        var code: String
        var name: String
        var limit: Int
        var description: String
        var rate: Double
        var margin: Double
        var specialty: String
        var expiresAt: Int
        var country: String
        var attributes: [String: String]
        var status: ConsentFormPreferenceStatus

        init(code: String, name: String, limit: Int, description: String, rate: Double, margin: Double, specialty: String, expiresAt: Int, country: String, attributes: [String: String], status: ConsentFormPreferenceStatus) {
            self.code = code
            self.name = name
            self.limit = limit
            self.description = description
            self.rate = rate
            self.margin = margin
            self.specialty = specialty
            self.expiresAt = expiresAt
            self.country = country
            self.attributes = attributes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ConsentFormPreferenceStatus) -> Bool {
            switch status {
            case .planned:
                return next == ConsentFormPreferenceStatus.completed || next == ConsentFormPreferenceStatus.cancelled
            case .scheduled:
                return next == ConsentFormPreferenceStatus.completed
            case .inProgress:
                return next == ConsentFormPreferenceStatus.completed
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: ConsentFormPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("consent form preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
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

        func projectedLoad() -> Double {
            return ((margin - Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> ConsentFormPreference {
            return ConsentFormPreference(
                code: code,
                name: name,
                limit: limit,
                description: description,
                rate: rate,
                margin: margin,
                specialty: specialty,
                expiresAt: expiresAt,
                country: country,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a consent form preference in status planned.
    static func newConsentFormPreference(_ code: String, name: String) -> ConsentFormPreference {
        return ConsentFormPreference(
            code: code,
            name: name,
            limit: 0,
            description: "",
            rate: 0.0,
            margin: 0.0,
            specialty: "",
            expiresAt: 0,
            country: "",
            attributes: [:],
            status: ConsentFormPreferenceStatus.planned
        )
    }
}
