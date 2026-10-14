import AcmePlatform
import Foundation

extension Labs {
    /// A rule a accession cycle must pass. Check returns its problems, or none.
    protocol AccessionCycleRule {
        func check(_ item: AccessionCycle) -> [String]
    }

    final class AccessionCycleRequiredLabelRule: AccessionCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AccessionCycle) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AccessionCycleRequiredLocaleRule: AccessionCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AccessionCycle) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AccessionCycleRequiredDiagnosisCodeRule: AccessionCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AccessionCycle) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AccessionCycleAllowedDiagnosisCodeRule: AccessionCycleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AccessionCycle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.diagnosisCode)) {
                return ["diagnosis code \(item.diagnosisCode) is above maximum"]
            }
            return []
        }
    }

    final class AccessionCycleVersionRangeRule: AccessionCycleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AccessionCycle) -> [String] {
            let value = item.version
            var problems: [String] = []
            if value < min {
                problems.append("version \(value) is below \(min)")
            }
            if value > max {
                problems.append("version \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a accession cycle.
    final class AccessionCycleValidator {
        var rules: [any AccessionCycleRule]

        init(rules: [any AccessionCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: AccessionCycle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                let found = rule.check(item)
                if found.count == 0 {
                    continue
                }
                for problem in found {
                    problems.append("\(item.code): \(problem)")
                }
            }
            return problems
        }

        func requireValid(_ item: AccessionCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AccessionCycle]) -> [String: [String]] {
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

    static func defaultAccessionCycleValidator() -> AccessionCycleValidator {
        return AccessionCycleValidator(
            rules: [
                AccessionCycleRequiredLabelRule(message: "accession cycle needs a value"),
                AccessionCycleRequiredLocaleRule(message: "accession cycle needs an entry"),
                AccessionCycleRequiredDiagnosisCodeRule(message: "accession cycle needs a value"),
                AccessionCycleAllowedDiagnosisCodeRule(allowed: ["tiered", "global"]),
                AccessionCycleVersionRangeRule(min: 64, max: 1000),
            ]
        )
    }
}
