import AcmePlatform
import Foundation

extension Consent {
    /// A rule a proxy baseline must pass. Check returns its problems, or none.
    protocol ProxyBaselineRule {
        func check(_ item: ProxyBaseline) -> [String]
    }

    final class ProxyBaselineCodeLengthRule: ProxyBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProxyBaseline) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProxyBaselineRequiredSegmentRule: ProxyBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProxyBaseline) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProxyBaselineGraceDaysRangeRule: ProxyBaselineRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ProxyBaseline) -> [String] {
            let value = item.graceDays
            var problems: [String] = []
            if value < min {
                problems.append("grace days \(value) is below \(min)")
            }
            if value > max {
                problems.append("grace days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ProxyBaselineCodePrefixRule: ProxyBaselineRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ProxyBaseline) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ProxyBaselineSegmentLengthRule: ProxyBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProxyBaseline) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a proxy baseline.
    final class ProxyBaselineValidator {
        var rules: [any ProxyBaselineRule]

        init(rules: [any ProxyBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: ProxyBaseline) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ProxyBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProxyBaseline]) -> [String: [String]] {
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

    static func defaultProxyBaselineValidator() -> ProxyBaselineValidator {
        return ProxyBaselineValidator(
            rules: [
                ProxyBaselineCodeLengthRule(maxLength: 86400),
                ProxyBaselineRequiredSegmentRule(message: "proxy baseline needs a value"),
                ProxyBaselineGraceDaysRangeRule(min: 16, max: 16),
                ProxyBaselineCodePrefixRule(prefix: "REF"),
                ProxyBaselineSegmentLengthRule(maxLength: 3600),
            ]
        )
    }
}
