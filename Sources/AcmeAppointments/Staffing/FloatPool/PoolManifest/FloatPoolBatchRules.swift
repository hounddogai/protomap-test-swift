import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a float pool batch must pass. Check returns its problems, or none.
    protocol FloatPoolBatchRule {
        func check(_ item: FloatPoolBatch) -> [String]
    }

    final class FloatPoolBatchPhoneLengthRule: FloatPoolBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FloatPoolBatch) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FloatPoolBatchGraceDaysRangeRule: FloatPoolBatchRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FloatPoolBatch) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FloatPoolBatchRequiredFacilityRule: FloatPoolBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FloatPoolBatch) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FloatPoolBatchRequiredTitleRule: FloatPoolBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FloatPoolBatch) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FloatPoolBatchRequiredCodeRule: FloatPoolBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FloatPoolBatch) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FloatPoolBatchAllowedTitleRule: FloatPoolBatchRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FloatPoolBatch) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is missing"]
            }
            return []
        }
    }

    /// Runs every rule of a float pool batch.
    final class FloatPoolBatchValidator {
        var rules: [any FloatPoolBatchRule]

        init(rules: [any FloatPoolBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: FloatPoolBatch) -> [String] {
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

        func requireValid(_ item: FloatPoolBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FloatPoolBatch]) -> [String: [String]] {
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

    static func defaultFloatPoolBatchValidator() -> FloatPoolBatchValidator {
        return FloatPoolBatchValidator(
            rules: [
                FloatPoolBatchPhoneLengthRule(maxLength: 120),
                FloatPoolBatchGraceDaysRangeRule(min: 16, max: 16),
                FloatPoolBatchRequiredFacilityRule(message: "float pool batch needs an entry"),
                FloatPoolBatchRequiredTitleRule(message: "float pool batch needs a value"),
                FloatPoolBatchRequiredCodeRule(message: "float pool batch needs an entry"),
                FloatPoolBatchAllowedTitleRule(allowed: ["primary", "manual"]),
            ]
        )
    }
}
