import AcmePlatform
import Foundation

extension Labs {
    /// A rule a courier threshold must pass. Check returns its problems, or none.
    protocol CourierThresholdRule {
        func check(_ item: CourierThreshold) -> [String]
    }

    final class CourierThresholdAllowedNameRule: CourierThresholdRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CourierThreshold) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is inconsistent"]
            }
            return []
        }
    }

    final class CourierThresholdPhoneLengthRule: CourierThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CourierThreshold) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CourierThresholdCodePrefixRule: CourierThresholdRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CourierThreshold) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CourierThresholdRefillsRangeRule: CourierThresholdRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CourierThreshold) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a courier threshold.
    final class CourierThresholdValidator {
        var rules: [any CourierThresholdRule]

        init(rules: [any CourierThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: CourierThreshold) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CourierThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CourierThreshold]) -> [String: [String]] {
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

    static func defaultCourierThresholdValidator() -> CourierThresholdValidator {
        return CourierThresholdValidator(
            rules: [
                CourierThresholdAllowedNameRule(allowed: []),
                CourierThresholdPhoneLengthRule(maxLength: 3600),
                CourierThresholdCodePrefixRule(prefix: "X"),
                CourierThresholdRefillsRangeRule(min: 120, max: 3600),
            ]
        )
    }
}
