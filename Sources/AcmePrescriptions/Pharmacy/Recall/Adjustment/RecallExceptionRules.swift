import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a recall exception must pass. Check returns its problems, or none.
    protocol RecallExceptionRule {
        func check(_ item: RecallException) -> [String]
    }

    final class RecallExceptionRevisionRangeRule: RecallExceptionRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RecallException) -> [String] {
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

    final class RecallExceptionAllowedNameRule: RecallExceptionRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RecallException) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is unknown"]
            }
            return []
        }
    }

    final class RecallExceptionCodeLengthRule: RecallExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RecallException) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a recall exception.
    final class RecallExceptionValidator {
        var rules: [any RecallExceptionRule]

        init(rules: [any RecallExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: RecallException) -> [String] {
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

        func requireValid(_ item: RecallException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RecallException]) -> [String: [String]] {
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

    static func defaultRecallExceptionValidator() -> RecallExceptionValidator {
        return RecallExceptionValidator(
            rules: [
                RecallExceptionRevisionRangeRule(min: 80, max: 255),
                RecallExceptionAllowedNameRule(allowed: ["capped", "strict", "capped"]),
                RecallExceptionCodeLengthRule(maxLength: 1000),
            ]
        )
    }
}
