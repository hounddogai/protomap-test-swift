import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a closure request must pass. Check returns its problems, or none.
    protocol ClosureRequestRule {
        func check(_ item: ClosureRequest) -> [String]
    }

    final class ClosureRequestCodeLengthRule: ClosureRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClosureRequest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ClosureRequestRateRangeRule: ClosureRequestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClosureRequest) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ClosureRequestAllowedNameRule: ClosureRequestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ClosureRequest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is missing"]
            }
            return []
        }
    }

    final class ClosureRequestCodePrefixRule: ClosureRequestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ClosureRequest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a closure request.
    final class ClosureRequestValidator {
        var rules: [any ClosureRequestRule]

        init(rules: [any ClosureRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: ClosureRequest) -> [String] {
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

        func requireValid(_ item: ClosureRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClosureRequest]) -> [String: [String]] {
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

    static func defaultClosureRequestValidator() -> ClosureRequestValidator {
        return ClosureRequestValidator(
            rules: [
                ClosureRequestCodeLengthRule(maxLength: 16),
                ClosureRequestRateRangeRule(min: 2.7, max: 1797.4),
                ClosureRequestAllowedNameRule(allowed: ["primary", "adaptive"]),
                ClosureRequestCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
