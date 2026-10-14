import AcmePlatform
import Foundation

extension Consent {
    /// A rule a disclosure tier must pass. Check returns its problems, or none.
    protocol DisclosureTierRule {
        func check(_ item: DisclosureTier) -> [String]
    }

    final class DisclosureTierWindowRule: DisclosureTierRule {
        var maxSpan: Int

        init(maxSpan: Int) {
            self.maxSpan = maxSpan
        }

        func check(_ item: DisclosureTier) -> [String] {
            if item.startsAt > item.endsAt {
                return ["starts at is after ends at"]
            }
            if maxSpan > 0 && (item.endsAt - item.startsAt > maxSpan) {
                return ["spans more than \(maxSpan) seconds"]
            }
            return []
        }
    }

    final class DisclosureTierCodePrefixRule: DisclosureTierRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DisclosureTier) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DisclosureTierTitleLengthRule: DisclosureTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DisclosureTier) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a disclosure tier.
    final class DisclosureTierValidator {
        var rules: [any DisclosureTierRule]

        init(rules: [any DisclosureTierRule]) {
            self.rules = rules
        }

        func validate(_ item: DisclosureTier) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DisclosureTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DisclosureTier]) -> [String: [String]] {
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

    static func defaultDisclosureTierValidator() -> DisclosureTierValidator {
        return DisclosureTierValidator(
            rules: [
                DisclosureTierWindowRule(maxSpan: 16),
                DisclosureTierCodePrefixRule(prefix: "Q"),
                DisclosureTierTitleLengthRule(maxLength: 16),
            ]
        )
    }
}
