import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a worklist bundle must pass. Check returns its problems, or none.
    protocol WorklistBundleRule {
        func check(_ item: WorklistBundle) -> [String]
    }

    final class WorklistBundleRequiredCodeRule: WorklistBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WorklistBundle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WorklistBundleRequiredDiagnosisCodeRule: WorklistBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WorklistBundle) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WorklistBundleAcuityRangeRule: WorklistBundleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WorklistBundle) -> [String] {
            let value = item.acuity
            if value < min || value > max {
                return ["acuity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WorklistBundleRefillsRangeRule: WorklistBundleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WorklistBundle) -> [String] {
            let value = item.refills
            var problems: [String] = []
            if value < min {
                problems.append("refills \(value) is below \(min)")
            }
            if value > max {
                problems.append("refills \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WorklistBundleCodePrefixRule: WorklistBundleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WorklistBundle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class WorklistBundleMinimumRangeRule: WorklistBundleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WorklistBundle) -> [String] {
            let value = item.minimum
            if value < min || value > max {
                return ["minimum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a worklist bundle.
    final class WorklistBundleValidator {
        var rules: [any WorklistBundleRule]

        init(rules: [any WorklistBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: WorklistBundle) -> [String] {
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

        func requireValid(_ item: WorklistBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WorklistBundle]) -> [String: [String]] {
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

    static func defaultWorklistBundleValidator() -> WorklistBundleValidator {
        return WorklistBundleValidator(
            rules: [
                WorklistBundleRequiredCodeRule(message: "worklist bundle needs a value"),
                WorklistBundleRequiredDiagnosisCodeRule(message: "worklist bundle needs this field"),
                WorklistBundleAcuityRangeRule(min: 64, max: 3600),
                WorklistBundleRefillsRangeRule(min: 16, max: 86400),
                WorklistBundleCodePrefixRule(prefix: "ACM"),
                WorklistBundleMinimumRangeRule(min: 7.6, max: 485.0),
            ]
        )
    }
}
