import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a care gap batch must pass. Check returns its problems, or none.
    protocol CareGapBatchRule {
        func check(_ item: CareGapBatch) -> [String]
    }

    final class CareGapBatchRequiredNameRule: CareGapBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareGapBatch) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareGapBatchAllowedNameRule: CareGapBatchRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CareGapBatch) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is unknown"]
            }
            return []
        }
    }

    final class CareGapBatchCodePrefixRule: CareGapBatchRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CareGapBatch) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CareGapBatchNameLengthRule: CareGapBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareGapBatch) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareGapBatchThresholdRangeRule: CareGapBatchRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareGapBatch) -> [String] {
            let value = item.threshold
            var problems: [String] = []
            if value < min {
                problems.append("threshold \(value) is below \(min)")
            }
            if value > max {
                problems.append("threshold \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CareGapBatchRequiredCodeRule: CareGapBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareGapBatch) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a care gap batch.
    final class CareGapBatchValidator {
        var rules: [any CareGapBatchRule]

        init(rules: [any CareGapBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: CareGapBatch) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CareGapBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareGapBatch]) -> [String: [String]] {
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

    static func defaultCareGapBatchValidator() -> CareGapBatchValidator {
        return CareGapBatchValidator(
            rules: [
                CareGapBatchRequiredNameRule(message: "care gap batch needs an entry"),
                CareGapBatchAllowedNameRule(allowed: ["batched"]),
                CareGapBatchCodePrefixRule(prefix: "REF"),
                CareGapBatchNameLengthRule(maxLength: 255),
                CareGapBatchThresholdRangeRule(min: 8.7, max: 3806.9),
                CareGapBatchRequiredCodeRule(message: "care gap batch needs a value"),
            ]
        )
    }
}
