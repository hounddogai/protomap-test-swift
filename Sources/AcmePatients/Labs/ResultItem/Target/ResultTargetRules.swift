import AcmePlatform
import Foundation

extension Labs {
    /// A rule a result target must pass. Check returns its problems, or none.
    protocol ResultTargetRule {
        func check(_ item: ResultTarget) -> [String]
    }

    final class ResultTargetCodeLengthRule: ResultTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ResultTarget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ResultTargetSummaryLengthRule: ResultTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ResultTarget) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ResultTargetNameLengthRule: ResultTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ResultTarget) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ResultTargetAllowedTimezoneRule: ResultTargetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ResultTarget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.timezone)) {
                return ["timezone \(item.timezone) is missing"]
            }
            return []
        }
    }

    /// Runs every rule of a result target.
    final class ResultTargetValidator {
        var rules: [any ResultTargetRule]

        init(rules: [any ResultTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: ResultTarget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ResultTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ResultTarget]) -> [String: [String]] {
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

    static func defaultResultTargetValidator() -> ResultTargetValidator {
        return ResultTargetValidator(
            rules: [
                ResultTargetCodeLengthRule(maxLength: 32),
                ResultTargetSummaryLengthRule(maxLength: 16),
                ResultTargetNameLengthRule(maxLength: 86400),
                ResultTargetAllowedTimezoneRule(allowed: ["capped"]),
            ]
        )
    }
}
