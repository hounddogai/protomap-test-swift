import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a batched substitution policy is in its life cycle.
    enum BatchedSubstitutionPolicyStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A batched substitution policy as the substitution team keeps it.
    final class BatchedSubstitutionPolicy {
        var code: String
        var name: String
        var score: Double
        var country: String
        var specialty: String
        var diagnosisCode: String
        var graceDays: Int
        var maximum: Double
        var source: String
        var ward: String
        var status: BatchedSubstitutionPolicyStatus

        init(code: String, name: String, score: Double, country: String, specialty: String, diagnosisCode: String, graceDays: Int, maximum: Double, source: String, ward: String, status: BatchedSubstitutionPolicyStatus) {
            self.code = code
            self.name = name
            self.score = score
            self.country = country
            self.specialty = specialty
            self.diagnosisCode = diagnosisCode
            self.graceDays = graceDays
            self.maximum = maximum
            self.source = source
            self.ward = ward
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

        func canMoveTo(_ next: BatchedSubstitutionPolicyStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == BatchedSubstitutionPolicyStatus.resolved
            case .resolved:
                return next == BatchedSubstitutionPolicyStatus.reopened || next == BatchedSubstitutionPolicyStatus.archived
            case .reopened:
                return next == BatchedSubstitutionPolicyStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedSubstitutionPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched substitution policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func weightedValue() -> Double {
            return ((maximum + score) * 100).rounded() / 100
        }

        func copyValue() -> BatchedSubstitutionPolicy {
            return BatchedSubstitutionPolicy(
                code: code,
                name: name,
                score: score,
                country: country,
                specialty: specialty,
                diagnosisCode: diagnosisCode,
                graceDays: graceDays,
                maximum: maximum,
                source: source,
                ward: ward,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a batched substitution policy in status open.
    static func newBatchedSubstitutionPolicy(_ code: String, name: String) -> BatchedSubstitutionPolicy {
        return BatchedSubstitutionPolicy(
            code: code,
            name: name,
            score: 0.0,
            country: "",
            specialty: "",
            diagnosisCode: "",
            graceDays: 0,
            maximum: 0.0,
            source: "",
            ward: "",
            status: BatchedSubstitutionPolicyStatus.`open`
        )
    }
}
