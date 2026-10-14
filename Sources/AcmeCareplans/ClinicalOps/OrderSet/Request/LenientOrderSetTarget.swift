import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a lenient order set target is in its life cycle.
    enum LenientOrderSetTargetStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A lenient order set target as the order set team keeps it.
    final class LenientOrderSetTarget {
        var code: String
        var name: String
        var budget: Double
        var revision: Int
        var phone: String
        var acuity: Int
        var attempts: Int
        var allergy: String
        var version: Int
        var country: String
        var status: LenientOrderSetTargetStatus

        init(code: String, name: String, budget: Double, revision: Int, phone: String, acuity: Int, attempts: Int, allergy: String, version: Int, country: String, status: LenientOrderSetTargetStatus) {
            self.code = code
            self.name = name
            self.budget = budget
            self.revision = revision
            self.phone = phone
            self.acuity = acuity
            self.attempts = attempts
            self.allergy = allergy
            self.version = version
            self.country = country
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

        func canMoveTo(_ next: LenientOrderSetTargetStatus) -> Bool {
            switch status {
            case .planned:
                return next == LenientOrderSetTargetStatus.scheduled
            case .scheduled:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == LenientOrderSetTargetStatus.completed
            case .completed:
                return next == LenientOrderSetTargetStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientOrderSetTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient order set target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func projectedExposure() -> Double {
            return ((Double(acuity) + Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> LenientOrderSetTarget {
            return LenientOrderSetTarget(
                code: code,
                name: name,
                budget: budget,
                revision: revision,
                phone: phone,
                acuity: acuity,
                attempts: attempts,
                allergy: allergy,
                version: version,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a lenient order set target in status planned.
    static func newLenientOrderSetTarget(_ code: String, name: String) -> LenientOrderSetTarget {
        return LenientOrderSetTarget(
            code: code,
            name: name,
            budget: 0.0,
            revision: 0,
            phone: "",
            acuity: 0,
            attempts: 0,
            allergy: "",
            version: 0,
            country: "",
            status: LenientOrderSetTargetStatus.planned
        )
    }
}
