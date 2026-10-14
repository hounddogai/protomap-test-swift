import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a read digest must pass. Check returns its problems, or none.
    protocol ReadDigestRule {
        func check(_ item: ReadDigest) -> [String]
    }

    final class ReadDigestRequiredCodeRule: ReadDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReadDigest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReadDigestAllowedCodeRule: ReadDigestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ReadDigest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is unknown"]
            }
            return []
        }
    }

    final class ReadDigestRequiredNameRule: ReadDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReadDigest) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReadDigestRateRangeRule: ReadDigestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReadDigest) -> [String] {
            let value = item.rate
            var problems: [String] = []
            if value < min {
                problems.append("rate \(value) is below \(min)")
            }
            if value > max {
                problems.append("rate \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ReadDigestCodePrefixRule: ReadDigestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ReadDigest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a read digest.
    final class ReadDigestValidator {
        var rules: [any ReadDigestRule]

        init(rules: [any ReadDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: ReadDigest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                let found = rule.check(item)
                if found.count == 0 {
                    continue
                }
                for problem in found {
                    problems.append("\(item.code): \(problem)")
                }
            }
            return problems
        }

        func requireValid(_ item: ReadDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReadDigest]) -> [String: [String]] {
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

    static func defaultReadDigestValidator() -> ReadDigestValidator {
        return ReadDigestValidator(
            rules: [
                ReadDigestRequiredCodeRule(message: "read digest needs this field"),
                ReadDigestAllowedCodeRule(allowed: ["default", "adaptive"]),
                ReadDigestRequiredNameRule(message: "read digest needs this field"),
                ReadDigestRateRangeRule(min: 10.0, max: 4957.0),
                ReadDigestCodePrefixRule(prefix: "X"),
            ]
        )
    }
}
