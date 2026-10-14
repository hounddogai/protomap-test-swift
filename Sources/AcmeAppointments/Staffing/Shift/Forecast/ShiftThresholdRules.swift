import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a shift threshold must pass. Check returns its problems, or none.
    protocol ShiftThresholdRule {
        func check(_ item: ShiftThreshold) -> [String]
    }

    final class ShiftThresholdRequiredNameRule: ShiftThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ShiftThreshold) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ShiftThresholdNameLengthRule: ShiftThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ShiftThreshold) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ShiftThresholdCodePrefixRule: ShiftThresholdRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ShiftThreshold) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ShiftThresholdWeightRangeRule: ShiftThresholdRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ShiftThreshold) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ShiftThresholdRequiredCodeRule: ShiftThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ShiftThreshold) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a shift threshold.
    final class ShiftThresholdValidator {
        var rules: [any ShiftThresholdRule]

        init(rules: [any ShiftThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: ShiftThreshold) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ShiftThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ShiftThreshold]) -> [String: [String]] {
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

    static func defaultShiftThresholdValidator() -> ShiftThresholdValidator {
        return ShiftThresholdValidator(
            rules: [
                ShiftThresholdRequiredNameRule(message: "shift threshold needs an entry"),
                ShiftThresholdNameLengthRule(maxLength: 3600),
                ShiftThresholdCodePrefixRule(prefix: "OPS"),
                ShiftThresholdWeightRangeRule(min: 1.9, max: 4631.8),
                ShiftThresholdRequiredCodeRule(message: "shift threshold needs this field"),
            ]
        )
    }
}
