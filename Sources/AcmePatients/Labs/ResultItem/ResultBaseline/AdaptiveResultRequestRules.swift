import AcmePlatform
import Foundation

extension Labs {
    /// A rule a adaptive result request must pass. Check returns its problems, or none.
    protocol AdaptiveResultRequestRule {
        func check(_ item: AdaptiveResultRequest) -> [String]
    }

    final class AdaptiveResultRequestCodeLengthRule: AdaptiveResultRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveResultRequest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveResultRequestCodePrefixRule: AdaptiveResultRequestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveResultRequest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AdaptiveResultRequestCreatedAtRangeRule: AdaptiveResultRequestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveResultRequest) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AdaptiveResultRequestDiscountRangeRule: AdaptiveResultRequestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveResultRequest) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AdaptiveResultRequestAllowedCodeRule: AdaptiveResultRequestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptiveResultRequest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is out of range"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive result request.
    final class AdaptiveResultRequestValidator {
        var rules: [any AdaptiveResultRequestRule]

        init(rules: [any AdaptiveResultRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveResultRequest) -> [String] {
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

        func requireValid(_ item: AdaptiveResultRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveResultRequest]) -> [String: [String]] {
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

    static func defaultAdaptiveResultRequestValidator() -> AdaptiveResultRequestValidator {
        return AdaptiveResultRequestValidator(
            rules: [
                AdaptiveResultRequestCodeLengthRule(maxLength: 255),
                AdaptiveResultRequestCodePrefixRule(prefix: "X"),
                AdaptiveResultRequestCreatedAtRangeRule(min: 32, max: 86400),
                AdaptiveResultRequestDiscountRangeRule(min: 4.0, max: 2311.9),
                AdaptiveResultRequestAllowedCodeRule(allowed: ["scheduled", "batched", "fallback"]),
            ]
        )
    }
}
