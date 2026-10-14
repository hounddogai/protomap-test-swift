import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a worklist rollup must pass. Check returns its problems, or none.
    protocol WorklistRollupRule {
        func check(_ item: WorklistRollup) -> [String]
    }

    final class WorklistRollupTitleLengthRule: WorklistRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WorklistRollup) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WorklistRollupCountryLengthRule: WorklistRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WorklistRollup) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WorklistRollupCodePrefixRule: WorklistRollupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WorklistRollup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class WorklistRollupCodeLengthRule: WorklistRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WorklistRollup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a worklist rollup.
    final class WorklistRollupValidator {
        var rules: [any WorklistRollupRule]

        init(rules: [any WorklistRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: WorklistRollup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WorklistRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WorklistRollup]) -> [String: [String]] {
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

    static func defaultWorklistRollupValidator() -> WorklistRollupValidator {
        return WorklistRollupValidator(
            rules: [
                WorklistRollupTitleLengthRule(maxLength: 86400),
                WorklistRollupCountryLengthRule(maxLength: 32),
                WorklistRollupCodePrefixRule(prefix: "REF"),
                WorklistRollupCodeLengthRule(maxLength: 3600),
            ]
        )
    }
}
