import AcmePlatform
import Foundation

extension Consent {
    /// A rule a proxy score must pass. Check returns its problems, or none.
    protocol ProxyScoreRule {
        func check(_ item: ProxyScore) -> [String]
    }

    final class ProxyScoreFacilityLengthRule: ProxyScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProxyScore) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProxyScoreCodeLengthRule: ProxyScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProxyScore) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProxyScoreRequiredTitleRule: ProxyScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProxyScore) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProxyScoreRatioRangeRule: ProxyScoreRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ProxyScore) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ProxyScoreRequiredCodeRule: ProxyScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProxyScore) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProxyScoreTitleLengthRule: ProxyScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProxyScore) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a proxy score.
    final class ProxyScoreValidator {
        var rules: [any ProxyScoreRule]

        init(rules: [any ProxyScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: ProxyScore) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ProxyScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProxyScore]) -> [String: [String]] {
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

    static func defaultProxyScoreValidator() -> ProxyScoreValidator {
        return ProxyScoreValidator(
            rules: [
                ProxyScoreFacilityLengthRule(maxLength: 120),
                ProxyScoreCodeLengthRule(maxLength: 16),
                ProxyScoreRequiredTitleRule(message: "proxy score needs this field"),
                ProxyScoreRatioRangeRule(min: 5.2, max: 3924.5),
                ProxyScoreRequiredCodeRule(message: "proxy score needs this field"),
                ProxyScoreTitleLengthRule(maxLength: 16),
            ]
        )
    }
}
