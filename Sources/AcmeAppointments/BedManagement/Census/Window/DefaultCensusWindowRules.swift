import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a default census window must pass. Check returns its problems, or none.
    protocol DefaultCensusWindowRule {
        func check(_ item: DefaultCensusWindow) -> [String]
    }

    final class DefaultCensusWindowRequiredCodeRule: DefaultCensusWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultCensusWindow) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultCensusWindowSourceLengthRule: DefaultCensusWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultCensusWindow) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultCensusWindowRequiredSourceRule: DefaultCensusWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultCensusWindow) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultCensusWindowRetriesRangeRule: DefaultCensusWindowRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultCensusWindow) -> [String] {
            let value = item.retries
            var problems: [String] = []
            if value < min {
                problems.append("retries \(value) is below \(min)")
            }
            if value > max {
                problems.append("retries \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DefaultCensusWindowCodeLengthRule: DefaultCensusWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultCensusWindow) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a default census window.
    final class DefaultCensusWindowValidator {
        var rules: [any DefaultCensusWindowRule]

        init(rules: [any DefaultCensusWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultCensusWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultCensusWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultCensusWindow]) -> [String: [String]] {
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

    static func defaultDefaultCensusWindowValidator() -> DefaultCensusWindowValidator {
        return DefaultCensusWindowValidator(
            rules: [
                DefaultCensusWindowRequiredCodeRule(message: "default census window needs this field"),
                DefaultCensusWindowSourceLengthRule(maxLength: 80),
                DefaultCensusWindowRequiredSourceRule(message: "default census window needs this field"),
                DefaultCensusWindowRetriesRangeRule(min: 1000, max: 86400),
                DefaultCensusWindowCodeLengthRule(maxLength: 255),
            ]
        )
    }
}
