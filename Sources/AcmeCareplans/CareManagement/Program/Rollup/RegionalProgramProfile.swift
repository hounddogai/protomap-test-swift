import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a regional program profile is in its life cycle.
    enum RegionalProgramProfileStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A regional program profile as the program team keeps it.
    final class RegionalProgramProfile {
        var code: String
        var name: String
        var attempts: Int
        var capacity: Int
        var diagnosisCode: String
        var minimum: Double
        var title: String
        var category: String
        var specialty: String
        var budget: Double
        var status: RegionalProgramProfileStatus

        init(code: String, name: String, attempts: Int, capacity: Int, diagnosisCode: String, minimum: Double, title: String, category: String, specialty: String, budget: Double, status: RegionalProgramProfileStatus) {
            self.code = code
            self.name = name
            self.attempts = attempts
            self.capacity = capacity
            self.diagnosisCode = diagnosisCode
            self.minimum = minimum
            self.title = title
            self.category = category
            self.specialty = specialty
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

        func canMoveTo(_ next: RegionalProgramProfileStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .done:
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
                return next == RegionalProgramProfileStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalProgramProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional program profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("regional program profile") \(code)"
        }

        func netTotal() -> Double {
            return (Double(capacity) * budget * 100).rounded() / 100
        }

        func copyValue() -> RegionalProgramProfile {
            return RegionalProgramProfile(
                code: code,
                name: name,
                attempts: attempts,
                capacity: capacity,
                diagnosisCode: diagnosisCode,
                minimum: minimum,
                title: title,
                category: category,
                specialty: specialty,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a regional program profile in status new.
    static func newRegionalProgramProfile(_ code: String, name: String) -> RegionalProgramProfile {
        return RegionalProgramProfile(
            code: code,
            name: name,
            attempts: 0,
            capacity: 0,
            diagnosisCode: "",
            minimum: 0.0,
            title: "",
            category: "",
            specialty: "",
            budget: 0.0,
            status: RegionalProgramProfileStatus.new
        )
    }
}
