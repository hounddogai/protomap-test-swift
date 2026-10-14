import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a denial bundle must pass. Check returns its problems, or none.
    protocol DenialBundleRule {
        func check(_ item: DenialBundle) -> [String]
    }

    final class DenialBundlePriorityRangeRule: DenialBundleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DenialBundle) -> [String] {
            let value = item.priority
            var problems: [String] = []
            if value < min {
                problems.append("priority \(value) is below \(min)")
            }
            if value > max {
                problems.append("priority \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DenialBundleNameLengthRule: DenialBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DenialBundle) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DenialBundleRequiredNameRule: DenialBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DenialBundle) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DenialBundleQuantityRangeRule: DenialBundleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DenialBundle) -> [String] {
            let value = item.quantity
            var problems: [String] = []
            if value < min {
                problems.append("quantity \(value) is below \(min)")
            }
            if value > max {
                problems.append("quantity \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a denial bundle.
    final class DenialBundleValidator {
        var rules: [any DenialBundleRule]

        init(rules: [any DenialBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: DenialBundle) -> [String] {
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

        func requireValid(_ item: DenialBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DenialBundle]) -> [String: [String]] {
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

    static func defaultDenialBundleValidator() -> DenialBundleValidator {
        return DenialBundleValidator(
            rules: [
                DenialBundlePriorityRangeRule(min: 80, max: 1000),
                DenialBundleNameLengthRule(maxLength: 255),
                DenialBundleRequiredNameRule(message: "denial bundle needs this field"),
                DenialBundleQuantityRangeRule(min: 80, max: 3600),
            ]
        )
    }
}
