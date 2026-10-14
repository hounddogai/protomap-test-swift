import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a batched dispense profile must pass. Check returns its problems, or none.
    protocol BatchedDispenseProfileRule {
        func check(_ item: BatchedDispenseProfile) -> [String]
    }

    final class BatchedDispenseProfileCodePrefixRule: BatchedDispenseProfileRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BatchedDispenseProfile) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class BatchedDispenseProfileRequiredNameRule: BatchedDispenseProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedDispenseProfile) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedDispenseProfileDurationMinutesRangeRule: BatchedDispenseProfileRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedDispenseProfile) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedDispenseProfileAllowedNameRule: BatchedDispenseProfileRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BatchedDispenseProfile) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is too long"]
            }
            return []
        }
    }

    final class BatchedDispenseProfileMaximumRangeRule: BatchedDispenseProfileRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedDispenseProfile) -> [String] {
            let value = item.maximum
            if value < min || value > max {
                return ["maximum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedDispenseProfileCapacityRangeRule: BatchedDispenseProfileRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedDispenseProfile) -> [String] {
            let value = item.capacity
            var problems: [String] = []
            if value < min {
                problems.append("capacity \(value) is below \(min)")
            }
            if value > max {
                problems.append("capacity \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a batched dispense profile.
    final class BatchedDispenseProfileValidator {
        var rules: [any BatchedDispenseProfileRule]

        init(rules: [any BatchedDispenseProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedDispenseProfile) -> [String] {
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

        func requireValid(_ item: BatchedDispenseProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedDispenseProfile]) -> [String: [String]] {
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

    static func defaultBatchedDispenseProfileValidator() -> BatchedDispenseProfileValidator {
        return BatchedDispenseProfileValidator(
            rules: [
                BatchedDispenseProfileCodePrefixRule(prefix: "ACM"),
                BatchedDispenseProfileRequiredNameRule(message: "batched dispense profile needs a value"),
                BatchedDispenseProfileDurationMinutesRangeRule(min: 16, max: 64),
                BatchedDispenseProfileAllowedNameRule(allowed: []),
                BatchedDispenseProfileMaximumRangeRule(min: 5.0, max: 3957.1),
                BatchedDispenseProfileCapacityRangeRule(min: 255, max: 255),
            ]
        )
    }
}
