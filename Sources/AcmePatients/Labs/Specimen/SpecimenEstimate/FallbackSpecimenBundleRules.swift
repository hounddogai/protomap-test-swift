import AcmePlatform
import Foundation

extension Labs {
    /// A rule a fallback specimen bundle must pass. Check returns its problems, or none.
    protocol FallbackSpecimenBundleRule {
        func check(_ item: FallbackSpecimenBundle) -> [String]
    }

    final class FallbackSpecimenBundleUnitLengthRule: FallbackSpecimenBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackSpecimenBundle) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackSpecimenBundleRequiredCodeRule: FallbackSpecimenBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackSpecimenBundle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackSpecimenBundleCodePrefixRule: FallbackSpecimenBundleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackSpecimenBundle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FallbackSpecimenBundleRevisionRangeRule: FallbackSpecimenBundleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackSpecimenBundle) -> [String] {
            let value = item.revision
            var problems: [String] = []
            if value < min {
                problems.append("revision \(value) is below \(min)")
            }
            if value > max {
                problems.append("revision \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FallbackSpecimenBundleRequiredLabelRule: FallbackSpecimenBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackSpecimenBundle) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a fallback specimen bundle.
    final class FallbackSpecimenBundleValidator {
        var rules: [any FallbackSpecimenBundleRule]

        init(rules: [any FallbackSpecimenBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackSpecimenBundle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackSpecimenBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackSpecimenBundle]) -> [String: [String]] {
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

    static func defaultFallbackSpecimenBundleValidator() -> FallbackSpecimenBundleValidator {
        return FallbackSpecimenBundleValidator(
            rules: [
                FallbackSpecimenBundleUnitLengthRule(maxLength: 1000),
                FallbackSpecimenBundleRequiredCodeRule(message: "fallback specimen bundle needs this field"),
                FallbackSpecimenBundleCodePrefixRule(prefix: "REF"),
                FallbackSpecimenBundleRevisionRangeRule(min: 64, max: 120),
                FallbackSpecimenBundleRequiredLabelRule(message: "fallback specimen bundle needs an entry"),
            ]
        )
    }
}
