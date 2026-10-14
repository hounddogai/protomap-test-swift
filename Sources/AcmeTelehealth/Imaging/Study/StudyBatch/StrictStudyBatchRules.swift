import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a strict study batch must pass. Check returns its problems, or none.
    protocol StrictStudyBatchRule {
        func check(_ item: StrictStudyBatch) -> [String]
    }

    final class StrictStudyBatchRequiredBedRule: StrictStudyBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictStudyBatch) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictStudyBatchRequiredChecksumRule: StrictStudyBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictStudyBatch) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictStudyBatchRequiredCodeRule: StrictStudyBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictStudyBatch) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictStudyBatchAllowedCodeRule: StrictStudyBatchRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StrictStudyBatch) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is blocked"]
            }
            return []
        }
    }

    final class StrictStudyBatchRefillsRangeRule: StrictStudyBatchRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictStudyBatch) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StrictStudyBatchRequiredTitleRule: StrictStudyBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictStudyBatch) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a strict study batch.
    final class StrictStudyBatchValidator {
        var rules: [any StrictStudyBatchRule]

        init(rules: [any StrictStudyBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictStudyBatch) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictStudyBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictStudyBatch]) -> [String: [String]] {
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

    static func defaultStrictStudyBatchValidator() -> StrictStudyBatchValidator {
        return StrictStudyBatchValidator(
            rules: [
                StrictStudyBatchRequiredBedRule(message: "strict study batch needs a value"),
                StrictStudyBatchRequiredChecksumRule(message: "strict study batch needs this field"),
                StrictStudyBatchRequiredCodeRule(message: "strict study batch needs this field"),
                StrictStudyBatchAllowedCodeRule(allowed: []),
                StrictStudyBatchRefillsRangeRule(min: 80, max: 86400),
                StrictStudyBatchRequiredTitleRule(message: "strict study batch needs a value"),
            ]
        )
    }
}
