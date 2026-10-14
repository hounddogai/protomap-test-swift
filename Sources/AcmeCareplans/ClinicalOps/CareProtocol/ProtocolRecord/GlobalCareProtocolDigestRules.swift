import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a global care protocol digest must pass. Check returns its problems, or none.
    protocol GlobalCareProtocolDigestRule {
        func check(_ item: GlobalCareProtocolDigest) -> [String]
    }

    final class GlobalCareProtocolDigestRateRangeRule: GlobalCareProtocolDigestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalCareProtocolDigest) -> [String] {
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

    final class GlobalCareProtocolDigestStartsAtRangeRule: GlobalCareProtocolDigestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalCareProtocolDigest) -> [String] {
            let value = item.startsAt
            if value < min || value > max {
                return ["starts at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalCareProtocolDigestCodePrefixRule: GlobalCareProtocolDigestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GlobalCareProtocolDigest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class GlobalCareProtocolDigestGraceDaysRangeRule: GlobalCareProtocolDigestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalCareProtocolDigest) -> [String] {
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

    final class GlobalCareProtocolDigestRequiredCodeRule: GlobalCareProtocolDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalCareProtocolDigest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a global care protocol digest.
    final class GlobalCareProtocolDigestValidator {
        var rules: [any GlobalCareProtocolDigestRule]

        init(rules: [any GlobalCareProtocolDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalCareProtocolDigest) -> [String] {
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

        func requireValid(_ item: GlobalCareProtocolDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalCareProtocolDigest]) -> [String: [String]] {
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

    static func defaultGlobalCareProtocolDigestValidator() -> GlobalCareProtocolDigestValidator {
        return GlobalCareProtocolDigestValidator(
            rules: [
                GlobalCareProtocolDigestRateRangeRule(min: 3.9, max: 4684.1),
                GlobalCareProtocolDigestStartsAtRangeRule(min: 32, max: 255),
                GlobalCareProtocolDigestCodePrefixRule(prefix: "Q"),
                GlobalCareProtocolDigestGraceDaysRangeRule(min: 32, max: 120),
                GlobalCareProtocolDigestRequiredCodeRule(message: "global care protocol digest needs an entry"),
            ]
        )
    }
}
