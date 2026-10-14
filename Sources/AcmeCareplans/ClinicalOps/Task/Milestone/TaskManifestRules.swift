import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a task manifest must pass. Check returns its problems, or none.
    protocol TaskManifestRule {
        func check(_ item: TaskManifest) -> [String]
    }

    final class TaskManifestAllergyLengthRule: TaskManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TaskManifest) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TaskManifestRequiredLabelRule: TaskManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TaskManifest) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TaskManifestRequiredCodeRule: TaskManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TaskManifest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TaskManifestCodePrefixRule: TaskManifestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TaskManifest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TaskManifestRatioRangeRule: TaskManifestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TaskManifest) -> [String] {
            let value = item.ratio
            var problems: [String] = []
            if value < min {
                problems.append("ratio \(value) is below \(min)")
            }
            if value > max {
                problems.append("ratio \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a task manifest.
    final class TaskManifestValidator {
        var rules: [any TaskManifestRule]

        init(rules: [any TaskManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: TaskManifest) -> [String] {
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

        func requireValid(_ item: TaskManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TaskManifest]) -> [String: [String]] {
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

    static func defaultTaskManifestValidator() -> TaskManifestValidator {
        return TaskManifestValidator(
            rules: [
                TaskManifestAllergyLengthRule(maxLength: 64),
                TaskManifestRequiredLabelRule(message: "task manifest needs this field"),
                TaskManifestRequiredCodeRule(message: "task manifest needs this field"),
                TaskManifestCodePrefixRule(prefix: "X"),
                TaskManifestRatioRangeRule(min: 7.0, max: 875.0),
            ]
        )
    }
}
