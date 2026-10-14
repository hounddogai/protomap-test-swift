import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a legacy dispense batch must pass. Check returns its problems, or none.
    protocol LegacyDispenseBatchRule {
        func check(_ item: LegacyDispenseBatch) -> [String]
    }

    final class LegacyDispenseBatchCodePrefixRule: LegacyDispenseBatchRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LegacyDispenseBatch) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LegacyDispenseBatchRequiredTitleRule: LegacyDispenseBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyDispenseBatch) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyDispenseBatchCategoryLengthRule: LegacyDispenseBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyDispenseBatch) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyDispenseBatchMaximumRangeRule: LegacyDispenseBatchRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyDispenseBatch) -> [String] {
            let value = item.maximum
            var problems: [String] = []
            if value < min {
                problems.append("maximum \(value) is below \(min)")
            }
            if value > max {
                problems.append("maximum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LegacyDispenseBatchAllowedFacilityRule: LegacyDispenseBatchRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LegacyDispenseBatch) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.facility)) {
                return ["facility \(item.facility) is duplicated"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy dispense batch.
    final class LegacyDispenseBatchValidator {
        var rules: [any LegacyDispenseBatchRule]

        init(rules: [any LegacyDispenseBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyDispenseBatch) -> [String] {
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

        func requireValid(_ item: LegacyDispenseBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyDispenseBatch]) -> [String: [String]] {
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

    static func defaultLegacyDispenseBatchValidator() -> LegacyDispenseBatchValidator {
        return LegacyDispenseBatchValidator(
            rules: [
                LegacyDispenseBatchCodePrefixRule(prefix: "X"),
                LegacyDispenseBatchRequiredTitleRule(message: "legacy dispense batch needs this field"),
                LegacyDispenseBatchCategoryLengthRule(maxLength: 3600),
                LegacyDispenseBatchMaximumRangeRule(min: 4.3, max: 3647.3),
                LegacyDispenseBatchAllowedFacilityRule(allowed: ["adaptive", "seasonal"]),
            ]
        )
    }
}
