import AcmePlatform
import Foundation

extension Labs {
    /// A rule a result window must pass. Check returns its problems, or none.
    protocol ResultWindowRule {
        func check(_ item: ResultWindow) -> [String]
    }

    final class ResultWindowRequiredSourceRule: ResultWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ResultWindow) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ResultWindowSourceLengthRule: ResultWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ResultWindow) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ResultWindowPinnedGuardRule: ResultWindowRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: ResultWindow) -> [String] {
            if item.pinned && (item.amount > limit) {
                return ["amount \(item.amount) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    /// Runs every rule of a result window.
    final class ResultWindowValidator {
        var rules: [any ResultWindowRule]

        init(rules: [any ResultWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: ResultWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ResultWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ResultWindow]) -> [String: [String]] {
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

    static func defaultResultWindowValidator() -> ResultWindowValidator {
        return ResultWindowValidator(
            rules: [
                ResultWindowRequiredSourceRule(message: "result window needs this field"),
                ResultWindowSourceLengthRule(maxLength: 1000),
                ResultWindowPinnedGuardRule(limit: 4.8),
            ]
        )
    }
}
