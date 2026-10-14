import AcmePlatform
import Foundation

extension Labs {
    /// A rule a batched specimen policy must pass. Check returns its problems, or none.
    protocol BatchedSpecimenPolicyRule {
        func check(_ item: BatchedSpecimenPolicy) -> [String]
    }

    final class BatchedSpecimenPolicyRequiredNameRule: BatchedSpecimenPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedSpecimenPolicy) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedSpecimenPolicyWindowDaysRangeRule: BatchedSpecimenPolicyRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedSpecimenPolicy) -> [String] {
            let value = item.windowDays
            var problems: [String] = []
            if value < min {
                problems.append("window days \(value) is below \(min)")
            }
            if value > max {
                problems.append("window days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BatchedSpecimenPolicyRequiredCodeRule: BatchedSpecimenPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedSpecimenPolicy) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedSpecimenPolicyAllowedCountryRule: BatchedSpecimenPolicyRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BatchedSpecimenPolicy) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.country)) {
                return ["country \(item.country) is below minimum"]
            }
            return []
        }
    }

    final class BatchedSpecimenPolicyUpdatedAtRangeRule: BatchedSpecimenPolicyRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedSpecimenPolicy) -> [String] {
            let value = item.updatedAt
            var problems: [String] = []
            if value < min {
                problems.append("updated at \(value) is below \(min)")
            }
            if value > max {
                problems.append("updated at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BatchedSpecimenPolicyCountryLengthRule: BatchedSpecimenPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedSpecimenPolicy) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched specimen policy.
    final class BatchedSpecimenPolicyValidator {
        var rules: [any BatchedSpecimenPolicyRule]

        init(rules: [any BatchedSpecimenPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedSpecimenPolicy) -> [String] {
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

        func requireValid(_ item: BatchedSpecimenPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedSpecimenPolicy]) -> [String: [String]] {
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

    static func defaultBatchedSpecimenPolicyValidator() -> BatchedSpecimenPolicyValidator {
        return BatchedSpecimenPolicyValidator(
            rules: [
                BatchedSpecimenPolicyRequiredNameRule(message: "batched specimen policy needs an entry"),
                BatchedSpecimenPolicyWindowDaysRangeRule(min: 32, max: 80),
                BatchedSpecimenPolicyRequiredCodeRule(message: "batched specimen policy needs a value"),
                BatchedSpecimenPolicyAllowedCountryRule(allowed: ["lenient"]),
                BatchedSpecimenPolicyUpdatedAtRangeRule(min: 120, max: 120),
                BatchedSpecimenPolicyCountryLengthRule(maxLength: 3600),
            ]
        )
    }
}
