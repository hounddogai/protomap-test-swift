import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a tiered read variance must pass. Check returns its problems, or none.
    protocol TieredReadVarianceRule {
        func check(_ item: TieredReadVariance) -> [String]
    }

    final class TieredReadVariancePriorityRangeRule: TieredReadVarianceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredReadVariance) -> [String] {
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

    final class TieredReadVarianceCodeLengthRule: TieredReadVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredReadVariance) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredReadVarianceRequiredLabelRule: TieredReadVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredReadVariance) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredReadVarianceRequiredCodeRule: TieredReadVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredReadVariance) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredReadVarianceRequiredTimezoneRule: TieredReadVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredReadVariance) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredReadVarianceAllowedChecksumRule: TieredReadVarianceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TieredReadVariance) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.checksum)) {
                return ["checksum \(item.checksum) is duplicated"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered read variance.
    final class TieredReadVarianceValidator {
        var rules: [any TieredReadVarianceRule]

        init(rules: [any TieredReadVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredReadVariance) -> [String] {
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

        func requireValid(_ item: TieredReadVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredReadVariance]) -> [String: [String]] {
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

    static func defaultTieredReadVarianceValidator() -> TieredReadVarianceValidator {
        return TieredReadVarianceValidator(
            rules: [
                TieredReadVariancePriorityRangeRule(min: 1000, max: 3600),
                TieredReadVarianceCodeLengthRule(maxLength: 16),
                TieredReadVarianceRequiredLabelRule(message: "tiered read variance needs a value"),
                TieredReadVarianceRequiredCodeRule(message: "tiered read variance needs a value"),
                TieredReadVarianceRequiredTimezoneRule(message: "tiered read variance needs this field"),
                TieredReadVarianceAllowedChecksumRule(allowed: ["pending"]),
            ]
        )
    }
}
