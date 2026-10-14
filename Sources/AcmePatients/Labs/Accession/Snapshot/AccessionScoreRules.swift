import AcmePlatform
import Foundation

extension Labs {
    /// A rule a accession score must pass. Check returns its problems, or none.
    protocol AccessionScoreRule {
        func check(_ item: AccessionScore) -> [String]
    }

    final class AccessionScoreRefillsRangeRule: AccessionScoreRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AccessionScore) -> [String] {
            let value = item.refills
            var problems: [String] = []
            if value < min {
                problems.append("refills \(value) is below \(min)")
            }
            if value > max {
                problems.append("refills \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AccessionScoreTitleLengthRule: AccessionScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AccessionScore) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AccessionScoreRequiredTitleRule: AccessionScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AccessionScore) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AccessionScoreCodePrefixRule: AccessionScoreRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AccessionScore) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a accession score.
    final class AccessionScoreValidator {
        var rules: [any AccessionScoreRule]

        init(rules: [any AccessionScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: AccessionScore) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AccessionScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AccessionScore]) -> [String: [String]] {
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

    static func defaultAccessionScoreValidator() -> AccessionScoreValidator {
        return AccessionScoreValidator(
            rules: [
                AccessionScoreRefillsRangeRule(min: 64, max: 120),
                AccessionScoreTitleLengthRule(maxLength: 255),
                AccessionScoreRequiredTitleRule(message: "accession score needs this field"),
                AccessionScoreCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
