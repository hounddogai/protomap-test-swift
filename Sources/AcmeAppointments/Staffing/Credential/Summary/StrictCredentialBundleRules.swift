import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a strict credential bundle must pass. Check returns its problems, or none.
    protocol StrictCredentialBundleRule {
        func check(_ item: StrictCredentialBundle) -> [String]
    }

    final class StrictCredentialBundleScoreRangeRule: StrictCredentialBundleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictCredentialBundle) -> [String] {
            let value = item.score
            var problems: [String] = []
            if value < min {
                problems.append("score \(value) is below \(min)")
            }
            if value > max {
                problems.append("score \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StrictCredentialBundleCostRangeRule: StrictCredentialBundleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictCredentialBundle) -> [String] {
            let value = item.cost
            if value < min || value > max {
                return ["cost \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StrictCredentialBundleRequiredCodeRule: StrictCredentialBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictCredentialBundle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictCredentialBundleNameLengthRule: StrictCredentialBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictCredentialBundle) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictCredentialBundleCodePrefixRule: StrictCredentialBundleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StrictCredentialBundle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class StrictCredentialBundleRequiredNameRule: StrictCredentialBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictCredentialBundle) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a strict credential bundle.
    final class StrictCredentialBundleValidator {
        var rules: [any StrictCredentialBundleRule]

        init(rules: [any StrictCredentialBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictCredentialBundle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictCredentialBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictCredentialBundle]) -> [String: [String]] {
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

    static func defaultStrictCredentialBundleValidator() -> StrictCredentialBundleValidator {
        return StrictCredentialBundleValidator(
            rules: [
                StrictCredentialBundleScoreRangeRule(min: 5.5, max: 3374.5),
                StrictCredentialBundleCostRangeRule(min: 4.0, max: 435.7),
                StrictCredentialBundleRequiredCodeRule(message: "strict credential bundle needs an entry"),
                StrictCredentialBundleNameLengthRule(maxLength: 3600),
                StrictCredentialBundleCodePrefixRule(prefix: "OPS"),
                StrictCredentialBundleRequiredNameRule(message: "strict credential bundle needs a value"),
            ]
        )
    }
}
