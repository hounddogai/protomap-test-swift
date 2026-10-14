import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a pending cleaning preference must pass. Check returns its problems, or none.
    protocol PendingCleaningPreferenceRule {
        func check(_ item: PendingCleaningPreference) -> [String]
    }

    final class PendingCleaningPreferenceExpiresAtRangeRule: PendingCleaningPreferenceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingCleaningPreference) -> [String] {
            let value = item.expiresAt
            var problems: [String] = []
            if value < min {
                problems.append("expires at \(value) is below \(min)")
            }
            if value > max {
                problems.append("expires at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PendingCleaningPreferenceExternalRefLengthRule: PendingCleaningPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingCleaningPreference) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingCleaningPreferenceRequiredCodeRule: PendingCleaningPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingCleaningPreference) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingCleaningPreferenceFloorValueRangeRule: PendingCleaningPreferenceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingCleaningPreference) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending cleaning preference.
    final class PendingCleaningPreferenceValidator {
        var rules: [any PendingCleaningPreferenceRule]

        init(rules: [any PendingCleaningPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingCleaningPreference) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingCleaningPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingCleaningPreference]) -> [String: [String]] {
            var report: [String: [String]] = [:]
            for item in items {
                let problems = self.validate(item)
                if problems.count > 0 {
                    report[item.code] = problems
                }
            }
            return report
        }
    }

    static func defaultPendingCleaningPreferenceValidator() -> PendingCleaningPreferenceValidator {
        return PendingCleaningPreferenceValidator(
            rules: [
                PendingCleaningPreferenceExpiresAtRangeRule(min: 1000, max: 1000),
                PendingCleaningPreferenceExternalRefLengthRule(maxLength: 255),
                PendingCleaningPreferenceRequiredCodeRule(message: "pending cleaning preference needs this field"),
                PendingCleaningPreferenceFloorValueRangeRule(min: 3.4, max: 1389.2),
            ]
        )
    }
}
