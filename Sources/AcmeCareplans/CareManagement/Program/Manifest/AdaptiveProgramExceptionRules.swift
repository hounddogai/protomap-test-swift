import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a adaptive program exception must pass. Check returns its problems, or none.
    protocol AdaptiveProgramExceptionRule {
        func check(_ item: AdaptiveProgramException) -> [String]
    }

    final class AdaptiveProgramExceptionCodePrefixRule: AdaptiveProgramExceptionRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveProgramException) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AdaptiveProgramExceptionNameLengthRule: AdaptiveProgramExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveProgramException) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveProgramExceptionAcuityRangeRule: AdaptiveProgramExceptionRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveProgramException) -> [String] {
            let value = item.acuity
            if value < min || value > max {
                return ["acuity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AdaptiveProgramExceptionCodeLengthRule: AdaptiveProgramExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveProgramException) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveProgramExceptionAllowedNameRule: AdaptiveProgramExceptionRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptiveProgramException) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is unknown"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive program exception.
    final class AdaptiveProgramExceptionValidator {
        var rules: [any AdaptiveProgramExceptionRule]

        init(rules: [any AdaptiveProgramExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveProgramException) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveProgramException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveProgramException]) -> [String: [String]] {
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

    static func defaultAdaptiveProgramExceptionValidator() -> AdaptiveProgramExceptionValidator {
        return AdaptiveProgramExceptionValidator(
            rules: [
                AdaptiveProgramExceptionCodePrefixRule(prefix: "Q"),
                AdaptiveProgramExceptionNameLengthRule(maxLength: 1000),
                AdaptiveProgramExceptionAcuityRangeRule(min: 32, max: 3600),
                AdaptiveProgramExceptionCodeLengthRule(maxLength: 86400),
                AdaptiveProgramExceptionAllowedNameRule(allowed: ["rolling", "pending"]),
            ]
        )
    }
}
