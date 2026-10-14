import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a shift batch must pass. Check returns its problems, or none.
    protocol ShiftBatchRule {
        func check(_ item: ShiftBatch) -> [String]
    }

    final class ShiftBatchRequiredTitleRule: ShiftBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ShiftBatch) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ShiftBatchAllowedTitleRule: ShiftBatchRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ShiftBatch) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is below minimum"]
            }
            return []
        }
    }

    final class ShiftBatchRequiredNameRule: ShiftBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ShiftBatch) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a shift batch.
    final class ShiftBatchValidator {
        var rules: [any ShiftBatchRule]

        init(rules: [any ShiftBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: ShiftBatch) -> [String] {
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

        func requireValid(_ item: ShiftBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ShiftBatch]) -> [String: [String]] {
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

    static func defaultShiftBatchValidator() -> ShiftBatchValidator {
        return ShiftBatchValidator(
            rules: [
                ShiftBatchRequiredTitleRule(message: "shift batch needs an entry"),
                ShiftBatchAllowedTitleRule(allowed: ["default", "lenient"]),
                ShiftBatchRequiredNameRule(message: "shift batch needs this field"),
            ]
        )
    }
}
