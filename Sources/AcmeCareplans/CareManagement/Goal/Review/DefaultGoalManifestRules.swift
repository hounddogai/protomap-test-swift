import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a default goal manifest must pass. Check returns its problems, or none.
    protocol DefaultGoalManifestRule {
        func check(_ item: DefaultGoalManifest) -> [String]
    }

    final class DefaultGoalManifestEndsAtRangeRule: DefaultGoalManifestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultGoalManifest) -> [String] {
            let value = item.endsAt
            var problems: [String] = []
            if value < min {
                problems.append("ends at \(value) is below \(min)")
            }
            if value > max {
                problems.append("ends at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DefaultGoalManifestRequiredCodeRule: DefaultGoalManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultGoalManifest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultGoalManifestRequiredCountryRule: DefaultGoalManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultGoalManifest) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultGoalManifestVisitMinutesRangeRule: DefaultGoalManifestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultGoalManifest) -> [String] {
            let value = item.visitMinutes
            var problems: [String] = []
            if value < min {
                problems.append("visit minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("visit minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DefaultGoalManifestCountryLengthRule: DefaultGoalManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultGoalManifest) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultGoalManifestRequiredSpecialtyRule: DefaultGoalManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultGoalManifest) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a default goal manifest.
    final class DefaultGoalManifestValidator {
        var rules: [any DefaultGoalManifestRule]

        init(rules: [any DefaultGoalManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultGoalManifest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultGoalManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultGoalManifest]) -> [String: [String]] {
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

    static func defaultDefaultGoalManifestValidator() -> DefaultGoalManifestValidator {
        return DefaultGoalManifestValidator(
            rules: [
                DefaultGoalManifestEndsAtRangeRule(min: 120, max: 3600),
                DefaultGoalManifestRequiredCodeRule(message: "default goal manifest needs this field"),
                DefaultGoalManifestRequiredCountryRule(message: "default goal manifest needs an entry"),
                DefaultGoalManifestVisitMinutesRangeRule(min: 16, max: 3600),
                DefaultGoalManifestCountryLengthRule(maxLength: 1000),
                DefaultGoalManifestRequiredSpecialtyRule(message: "default goal manifest needs a value"),
            ]
        )
    }
}
