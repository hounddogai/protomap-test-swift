import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a primary denial score must pass. Check returns its problems, or none.
    protocol PrimaryDenialScoreRule {
        func check(_ item: PrimaryDenialScore) -> [String]
    }

    final class PrimaryDenialScoreCodeLengthRule: PrimaryDenialScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryDenialScore) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryDenialScoreCodePrefixRule: PrimaryDenialScoreRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PrimaryDenialScore) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PrimaryDenialScoreRequiredSpecialtyRule: PrimaryDenialScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryDenialScore) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a primary denial score.
    final class PrimaryDenialScoreValidator {
        var rules: [any PrimaryDenialScoreRule]

        init(rules: [any PrimaryDenialScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryDenialScore) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryDenialScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryDenialScore]) -> [String: [String]] {
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

    static func defaultPrimaryDenialScoreValidator() -> PrimaryDenialScoreValidator {
        return PrimaryDenialScoreValidator(
            rules: [
                PrimaryDenialScoreCodeLengthRule(maxLength: 1000),
                PrimaryDenialScoreCodePrefixRule(prefix: "REF"),
                PrimaryDenialScoreRequiredSpecialtyRule(message: "primary denial score needs a value"),
            ]
        )
    }
}
