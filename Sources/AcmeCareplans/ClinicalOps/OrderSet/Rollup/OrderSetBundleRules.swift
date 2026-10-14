import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a order set bundle must pass. Check returns its problems, or none.
    protocol OrderSetBundleRule {
        func check(_ item: OrderSetBundle) -> [String]
    }

    final class OrderSetBundleFloorValueRangeRule: OrderSetBundleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: OrderSetBundle) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class OrderSetBundleCodeLengthRule: OrderSetBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OrderSetBundle) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OrderSetBundleRequiredCodeRule: OrderSetBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OrderSetBundle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OrderSetBundleTitleLengthRule: OrderSetBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OrderSetBundle) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OrderSetBundleAllowedCodeRule: OrderSetBundleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: OrderSetBundle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is blocked"]
            }
            return []
        }
    }

    /// Runs every rule of a order set bundle.
    final class OrderSetBundleValidator {
        var rules: [any OrderSetBundleRule]

        init(rules: [any OrderSetBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: OrderSetBundle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: OrderSetBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OrderSetBundle]) -> [String: [String]] {
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

    static func defaultOrderSetBundleValidator() -> OrderSetBundleValidator {
        return OrderSetBundleValidator(
            rules: [
                OrderSetBundleFloorValueRangeRule(min: 0.9, max: 2797.2),
                OrderSetBundleCodeLengthRule(maxLength: 86400),
                OrderSetBundleRequiredCodeRule(message: "order set bundle needs a value"),
                OrderSetBundleTitleLengthRule(maxLength: 120),
                OrderSetBundleAllowedCodeRule(allowed: ["tiered"]),
            ]
        )
    }
}
