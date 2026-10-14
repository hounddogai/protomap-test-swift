import AcmePlatform
import Foundation

extension Consent {
    /// A rule a proxy entry must pass. Check returns its problems, or none.
    protocol ProxyEntryRule {
        func check(_ item: ProxyEntry) -> [String]
    }

    final class ProxyEntryAllowedLabelRule: ProxyEntryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ProxyEntry) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is out of range"]
            }
            return []
        }
    }

    final class ProxyEntryRequiredSummaryRule: ProxyEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProxyEntry) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProxyEntrySummaryLengthRule: ProxyEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProxyEntry) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProxyEntryStartsAtRangeRule: ProxyEntryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ProxyEntry) -> [String] {
            let value = item.startsAt
            var problems: [String] = []
            if value < min {
                problems.append("starts at \(value) is below \(min)")
            }
            if value > max {
                problems.append("starts at \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a proxy entry.
    final class ProxyEntryValidator {
        var rules: [any ProxyEntryRule]

        init(rules: [any ProxyEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: ProxyEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ProxyEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProxyEntry]) -> [String: [String]] {
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

    static func defaultProxyEntryValidator() -> ProxyEntryValidator {
        return ProxyEntryValidator(
            rules: [
                ProxyEntryAllowedLabelRule(allowed: []),
                ProxyEntryRequiredSummaryRule(message: "proxy entry needs an entry"),
                ProxyEntrySummaryLengthRule(maxLength: 255),
                ProxyEntryStartsAtRangeRule(min: 64, max: 86400),
            ]
        )
    }
}
