import AcmePlatform
import Foundation

extension Labs {
    /// A rule a accession bundle must pass. Check returns its problems, or none.
    protocol AccessionBundleRule {
        func check(_ item: AccessionBundle) -> [String]
    }

    final class AccessionBundleBedLengthRule: AccessionBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AccessionBundle) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AccessionBundleRequiredCodeRule: AccessionBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AccessionBundle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AccessionBundleAmountRangeRule: AccessionBundleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AccessionBundle) -> [String] {
            let value = item.amount
            var problems: [String] = []
            if value < min {
                problems.append("amount \(value) is below \(min)")
            }
            if value > max {
                problems.append("amount \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a accession bundle.
    final class AccessionBundleValidator {
        var rules: [any AccessionBundleRule]

        init(rules: [any AccessionBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: AccessionBundle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AccessionBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AccessionBundle]) -> [String: [String]] {
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

    static func defaultAccessionBundleValidator() -> AccessionBundleValidator {
        return AccessionBundleValidator(
            rules: [
                AccessionBundleBedLengthRule(maxLength: 86400),
                AccessionBundleRequiredCodeRule(message: "accession bundle needs a value"),
                AccessionBundleAmountRangeRule(min: 8.3, max: 2058.4),
            ]
        )
    }
}
