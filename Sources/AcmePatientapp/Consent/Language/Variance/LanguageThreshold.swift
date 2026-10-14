import AcmePlatform
import Foundation

extension Consent {
    /// Where a language threshold is in its life cycle.
    enum LanguageThresholdStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One language threshold, with what the planners need to act on it.
    final class LanguageThreshold {
        var code: String
        var label: String
        var country: String
        var allergy: String
        var version: Int
        var category: String
        var maximum: Double
        var priority: Int
        var facility: String
        var status: LanguageThresholdStatus

        init(code: String, label: String, country: String, allergy: String, version: Int, category: String, maximum: Double, priority: Int, facility: String, status: LanguageThresholdStatus) {
            self.code = code
            self.label = label
            self.country = country
            self.allergy = allergy
            self.version = version
            self.category = category
            self.maximum = maximum
            self.priority = priority
            self.facility = facility
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

        func canMoveTo(_ next: LanguageThresholdStatus) -> Bool {
            switch status {
            case .new:
                return next == LanguageThresholdStatus.running || next == LanguageThresholdStatus.failed
            case .queued:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == LanguageThresholdStatus.done
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

        func moveTo(_ next: LanguageThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("language threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func projectedLoad() -> Double {
            return ((Double(version) - Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> LanguageThreshold {
            return LanguageThreshold(
                code: code,
                label: label,
                country: country,
                allergy: allergy,
                version: version,
                category: category,
                maximum: maximum,
                priority: priority,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a language threshold in status new.
    static func newLanguageThreshold(_ code: String, label: String) -> LanguageThreshold {
        return LanguageThreshold(
            code: code,
            label: label,
            country: "",
            allergy: "",
            version: 0,
            category: "",
            maximum: 0.0,
            priority: 0,
            facility: "",
            status: LanguageThresholdStatus.new
        )
    }
}
