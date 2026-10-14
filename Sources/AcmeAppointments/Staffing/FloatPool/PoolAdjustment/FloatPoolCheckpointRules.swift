import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a float pool checkpoint must pass. Check returns its problems, or none.
    protocol FloatPoolCheckpointRule {
        func check(_ item: FloatPoolCheckpoint) -> [String]
    }

    final class FloatPoolCheckpointRetriesRangeRule: FloatPoolCheckpointRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FloatPoolCheckpoint) -> [String] {
            let value = item.retries
            if value < min || value > max {
                return ["retries \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FloatPoolCheckpointRequiredWardRule: FloatPoolCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FloatPoolCheckpoint) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FloatPoolCheckpointCodePrefixRule: FloatPoolCheckpointRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FloatPoolCheckpoint) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FloatPoolCheckpointRequiredAllergyRule: FloatPoolCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FloatPoolCheckpoint) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FloatPoolCheckpointLabelLengthRule: FloatPoolCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FloatPoolCheckpoint) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a float pool checkpoint.
    final class FloatPoolCheckpointValidator {
        var rules: [any FloatPoolCheckpointRule]

        init(rules: [any FloatPoolCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: FloatPoolCheckpoint) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FloatPoolCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FloatPoolCheckpoint]) -> [String: [String]] {
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

    static func defaultFloatPoolCheckpointValidator() -> FloatPoolCheckpointValidator {
        return FloatPoolCheckpointValidator(
            rules: [
                FloatPoolCheckpointRetriesRangeRule(min: 120, max: 1000),
                FloatPoolCheckpointRequiredWardRule(message: "float pool checkpoint needs an entry"),
                FloatPoolCheckpointCodePrefixRule(prefix: "OPS"),
                FloatPoolCheckpointRequiredAllergyRule(message: "float pool checkpoint needs a value"),
                FloatPoolCheckpointLabelLengthRule(maxLength: 16),
            ]
        )
    }
}
