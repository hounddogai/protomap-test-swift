import AcmePlatform
import Foundation

extension Consent {
    /// Where a consent form score is in its life cycle.
    enum ConsentFormScoreStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One consent form score, with what the planners need to act on it.
    final class ConsentFormScore {
        var code: String
        var name: String
        var ratio: Double
        var budget: Double
        var attributes: [String: String]
        var ward: String
        var procedureCode: String
        var pinned: Bool
        var startsAt: Int
        var timezone: String
        var attempts: Int
        var status: ConsentFormScoreStatus

        init(code: String, name: String, ratio: Double, budget: Double, attributes: [String: String], ward: String, procedureCode: String, pinned: Bool, startsAt: Int, timezone: String, attempts: Int, status: ConsentFormScoreStatus) {
            self.code = code
            self.name = name
            self.ratio = ratio
            self.budget = budget
            self.attributes = attributes
            self.ward = ward
            self.procedureCode = procedureCode
            self.pinned = pinned
            self.startsAt = startsAt
            self.timezone = timezone
            self.attempts = attempts
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

        func canMoveTo(_ next: ConsentFormScoreStatus) -> Bool {
            switch status {
            case .requested:
                return next == ConsentFormScoreStatus.expired
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: ConsentFormScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("consent form score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
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

        func weightedVolume() -> Double {
            return (Double(startsAt) * budget * 100).rounded() / 100
        }

        func copyValue() -> ConsentFormScore {
            return ConsentFormScore(
                code: code,
                name: name,
                ratio: ratio,
                budget: budget,
                attributes: attributes,
                ward: ward,
                procedureCode: procedureCode,
                pinned: pinned,
                startsAt: startsAt,
                timezone: timezone,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a consent form score in status requested.
    static func newConsentFormScore(_ code: String, name: String) -> ConsentFormScore {
        return ConsentFormScore(
            code: code,
            name: name,
            ratio: 0.0,
            budget: 0.0,
            attributes: [:],
            ward: "",
            procedureCode: "",
            pinned: false,
            startsAt: 0,
            timezone: "",
            attempts: 0,
            status: ConsentFormScoreStatus.requested
        )
    }
}
