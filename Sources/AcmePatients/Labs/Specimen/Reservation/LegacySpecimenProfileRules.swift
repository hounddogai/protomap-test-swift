import AcmePlatform
import Foundation

extension Labs {
    /// A rule a legacy specimen profile must pass. Check returns its problems, or none.
    protocol LegacySpecimenProfileRule {
        func check(_ item: LegacySpecimenProfile) -> [String]
    }

    final class LegacySpecimenProfileRequiredLabelRule: LegacySpecimenProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacySpecimenProfile) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacySpecimenProfileMinimumRangeRule: LegacySpecimenProfileRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacySpecimenProfile) -> [String] {
            let value = item.minimum
            var problems: [String] = []
            if value < min {
                problems.append("minimum \(value) is below \(min)")
            }
            if value > max {
                problems.append("minimum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LegacySpecimenProfileRequiredCodeRule: LegacySpecimenProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacySpecimenProfile) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacySpecimenProfileRequiredOwnerIDRule: LegacySpecimenProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacySpecimenProfile) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a legacy specimen profile.
    final class LegacySpecimenProfileValidator {
        var rules: [any LegacySpecimenProfileRule]

        init(rules: [any LegacySpecimenProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacySpecimenProfile) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacySpecimenProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacySpecimenProfile]) -> [String: [String]] {
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

    static func defaultLegacySpecimenProfileValidator() -> LegacySpecimenProfileValidator {
        return LegacySpecimenProfileValidator(
            rules: [
                LegacySpecimenProfileRequiredLabelRule(message: "legacy specimen profile needs an entry"),
                LegacySpecimenProfileMinimumRangeRule(min: 6.7, max: 2027.4),
                LegacySpecimenProfileRequiredCodeRule(message: "legacy specimen profile needs this field"),
                LegacySpecimenProfileRequiredOwnerIDRule(message: "legacy specimen profile needs an entry"),
            ]
        )
    }
}
