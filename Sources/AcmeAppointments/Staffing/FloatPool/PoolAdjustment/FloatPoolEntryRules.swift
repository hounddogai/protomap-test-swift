import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a float pool entry must pass. Check returns its problems, or none.
    protocol FloatPoolEntryRule {
        func check(_ item: FloatPoolEntry) -> [String]
    }

    final class FloatPoolEntryMarginRangeRule: FloatPoolEntryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FloatPoolEntry) -> [String] {
            let value = item.margin
            if value < min || value > max {
                return ["margin \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FloatPoolEntryAllowedCodeRule: FloatPoolEntryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FloatPoolEntry) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is stale"]
            }
            return []
        }
    }

    final class FloatPoolEntrySummaryLengthRule: FloatPoolEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FloatPoolEntry) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FloatPoolEntryRequiredNameRule: FloatPoolEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FloatPoolEntry) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FloatPoolEntryWindowDaysRangeRule: FloatPoolEntryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FloatPoolEntry) -> [String] {
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

    final class FloatPoolEntryNameLengthRule: FloatPoolEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FloatPoolEntry) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a float pool entry.
    final class FloatPoolEntryValidator {
        var rules: [any FloatPoolEntryRule]

        init(rules: [any FloatPoolEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: FloatPoolEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FloatPoolEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FloatPoolEntry]) -> [String: [String]] {
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

    static func defaultFloatPoolEntryValidator() -> FloatPoolEntryValidator {
        return FloatPoolEntryValidator(
            rules: [
                FloatPoolEntryMarginRangeRule(min: 8.0, max: 2381.3),
                FloatPoolEntryAllowedCodeRule(allowed: ["batched", "fallback", "manual"]),
                FloatPoolEntrySummaryLengthRule(maxLength: 120),
                FloatPoolEntryRequiredNameRule(message: "float pool entry needs an entry"),
                FloatPoolEntryWindowDaysRangeRule(min: 80, max: 120),
                FloatPoolEntryNameLengthRule(maxLength: 80),
            ]
        )
    }
}
