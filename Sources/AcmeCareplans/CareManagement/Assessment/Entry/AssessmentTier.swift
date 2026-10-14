import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a assessment tier is in its life cycle.
    enum AssessmentTierStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A assessment tier as the assessment team keeps it.
    final class AssessmentTier {
        var code: String
        var name: String
        var bed: String
        var locale: String
        var budget: Double
        var status: AssessmentTierStatus

        init(code: String, name: String, bed: String, locale: String, budget: Double, status: AssessmentTierStatus) {
            self.code = code
            self.name = name
            self.bed = bed
            self.locale = locale
            self.budget = budget
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

        func canMoveTo(_ next: AssessmentTierStatus) -> Bool {
            switch status {
            case .new:
                return next == AssessmentTierStatus.queued || next == AssessmentTierStatus.failed
            case .queued:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: AssessmentTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("assessment tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func measuredValue() -> Double {
            return budget
        }

        func copyValue() -> AssessmentTier {
            return AssessmentTier(code: code, name: name, bed: bed, locale: locale, budget: budget, status: status)
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a assessment tier in status new.
    static func newAssessmentTier(_ code: String, name: String) -> AssessmentTier {
        return AssessmentTier(
            code: code,
            name: name,
            bed: "",
            locale: "",
            budget: 0.0,
            status: AssessmentTierStatus.new
        )
    }
}
