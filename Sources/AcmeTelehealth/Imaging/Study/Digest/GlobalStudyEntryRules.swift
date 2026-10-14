import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a global study entry must pass. Check returns its problems, or none.
    protocol GlobalStudyEntryRule {
        func check(_ item: GlobalStudyEntry) -> [String]
    }

    final class GlobalStudyEntryCodeLengthRule: GlobalStudyEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalStudyEntry) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalStudyEntryRequiredCodeRule: GlobalStudyEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalStudyEntry) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalStudyEntryBatchSizeRangeRule: GlobalStudyEntryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalStudyEntry) -> [String] {
            let value = item.batchSize
            if value < min || value > max {
                return ["batch size \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalStudyEntryAllowedCodeRule: GlobalStudyEntryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GlobalStudyEntry) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is out of range"]
            }
            return []
        }
    }

    /// Runs every rule of a global study entry.
    final class GlobalStudyEntryValidator {
        var rules: [any GlobalStudyEntryRule]

        init(rules: [any GlobalStudyEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalStudyEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalStudyEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalStudyEntry]) -> [String: [String]] {
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

    static func defaultGlobalStudyEntryValidator() -> GlobalStudyEntryValidator {
        return GlobalStudyEntryValidator(
            rules: [
                GlobalStudyEntryCodeLengthRule(maxLength: 120),
                GlobalStudyEntryRequiredCodeRule(message: "global study entry needs a value"),
                GlobalStudyEntryBatchSizeRangeRule(min: 32, max: 120),
                GlobalStudyEntryAllowedCodeRule(allowed: ["lenient", "lenient", "manual"]),
            ]
        )
    }
}
