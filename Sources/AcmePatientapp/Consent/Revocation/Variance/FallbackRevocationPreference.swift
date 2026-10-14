import AcmePlatform
import Foundation

extension Consent {
    /// Where a fallback revocation preference is in its life cycle.
    enum FallbackRevocationPreferenceStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A fallback revocation preference as the revocation team keeps it.
    final class FallbackRevocationPreference {
        var code: String
        var name: String
        var country: String
        var diagnosisCode: String
        var margin: Double
        var refills: Int
        var score: Double
        var createdAt: Int
        var summary: String
        var attempts: Int
        var status: FallbackRevocationPreferenceStatus

        init(code: String, name: String, country: String, diagnosisCode: String, margin: Double, refills: Int, score: Double, createdAt: Int, summary: String, attempts: Int, status: FallbackRevocationPreferenceStatus) {
            self.code = code
            self.name = name
            self.country = country
            self.diagnosisCode = diagnosisCode
            self.margin = margin
            self.refills = refills
            self.score = score
            self.createdAt = createdAt
            self.summary = summary
            self.attempts = attempts
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FallbackRevocationPreferenceStatus) -> Bool {
            switch status {
            case .proposed:
                return next == FallbackRevocationPreferenceStatus.approved || next == FallbackRevocationPreferenceStatus.rejected
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == FallbackRevocationPreferenceStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackRevocationPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback revocation preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func projectedExposure() -> Double {
            return (score * Double(refills) * 100).rounded() / 100
        }

        func copyValue() -> FallbackRevocationPreference {
            return FallbackRevocationPreference(
                code: code,
                name: name,
                country: country,
                diagnosisCode: diagnosisCode,
                margin: margin,
                refills: refills,
                score: score,
                createdAt: createdAt,
                summary: summary,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a fallback revocation preference in status proposed.
    static func newFallbackRevocationPreference(_ code: String, name: String) -> FallbackRevocationPreference {
        return FallbackRevocationPreference(
            code: code,
            name: name,
            country: "",
            diagnosisCode: "",
            margin: 0.0,
            refills: 0,
            score: 0.0,
            createdAt: 0,
            summary: "",
            attempts: 0,
            status: FallbackRevocationPreferenceStatus.proposed
        )
    }
}
