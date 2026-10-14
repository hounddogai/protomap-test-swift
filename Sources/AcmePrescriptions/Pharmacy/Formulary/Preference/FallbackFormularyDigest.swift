import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a fallback formulary digest is in its life cycle.
    enum FallbackFormularyDigestStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One fallback formulary digest, with what the planners need to act on it.
    final class FallbackFormularyDigest {
        var code: String
        var name: String
        var specialty: String
        var patientRef: String
        var weight: Double
        var limit: Int
        var budget: Double
        var score: Double
        var timezone: String
        var attempts: Int
        var ceiling: Double
        var status: FallbackFormularyDigestStatus

        init(code: String, name: String, specialty: String, patientRef: String, weight: Double, limit: Int, budget: Double, score: Double, timezone: String, attempts: Int, ceiling: Double, status: FallbackFormularyDigestStatus) {
            self.code = code
            self.name = name
            self.specialty = specialty
            self.patientRef = patientRef
            self.weight = weight
            self.limit = limit
            self.budget = budget
            self.score = score
            self.timezone = timezone
            self.attempts = attempts
            self.ceiling = ceiling
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FallbackFormularyDigestStatus) -> Bool {
            switch status {
            case .`open`:
                return next == FallbackFormularyDigestStatus.archived
            case .inReview:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == FallbackFormularyDigestStatus.reopened || next == FallbackFormularyDigestStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: FallbackFormularyDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback formulary digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func adjustedLoad() -> Double {
            return ((weight - score) * 100).rounded() / 100
        }

        func copyValue() -> FallbackFormularyDigest {
            return FallbackFormularyDigest(
                code: code,
                name: name,
                specialty: specialty,
                patientRef: patientRef,
                weight: weight,
                limit: limit,
                budget: budget,
                score: score,
                timezone: timezone,
                attempts: attempts,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a fallback formulary digest in status open.
    static func newFallbackFormularyDigest(_ code: String, name: String) -> FallbackFormularyDigest {
        return FallbackFormularyDigest(
            code: code,
            name: name,
            specialty: "",
            patientRef: "",
            weight: 0.0,
            limit: 0,
            budget: 0.0,
            score: 0.0,
            timezone: "",
            attempts: 0,
            ceiling: 0.0,
            status: FallbackFormularyDigestStatus.`open`
        )
    }
}
