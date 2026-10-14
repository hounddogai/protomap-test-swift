import AcmePlatform
import Foundation

extension Labs {
    /// A rule a reference range tier must pass. Check returns its problems, or none.
    protocol ReferenceRangeTierRule {
        func check(_ item: ReferenceRangeTier) -> [String]
    }

    final class ReferenceRangeTierAllowedCodeRule: ReferenceRangeTierRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ReferenceRangeTier) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is out of range"]
            }
            return []
        }
    }

    final class ReferenceRangeTierRequiredCodeRule: ReferenceRangeTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferenceRangeTier) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferenceRangeTierLocaleLengthRule: ReferenceRangeTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferenceRangeTier) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferenceRangeTierLabelLengthRule: ReferenceRangeTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferenceRangeTier) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferenceRangeTierRatioRangeRule: ReferenceRangeTierRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferenceRangeTier) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a reference range tier.
    final class ReferenceRangeTierValidator {
        var rules: [any ReferenceRangeTierRule]

        init(rules: [any ReferenceRangeTierRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferenceRangeTier) -> [String] {
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

        func requireValid(_ item: ReferenceRangeTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferenceRangeTier]) -> [String: [String]] {
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

    static func defaultReferenceRangeTierValidator() -> ReferenceRangeTierValidator {
        return ReferenceRangeTierValidator(
            rules: [
                ReferenceRangeTierAllowedCodeRule(allowed: ["lenient"]),
                ReferenceRangeTierRequiredCodeRule(message: "reference range tier needs an entry"),
                ReferenceRangeTierLocaleLengthRule(maxLength: 1000),
                ReferenceRangeTierLabelLengthRule(maxLength: 255),
                ReferenceRangeTierRatioRangeRule(min: 9.2, max: 2531.2),
            ]
        )
    }
}
