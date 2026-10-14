import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a strict care protocol target must pass. Check returns its problems, or none.
    protocol StrictCareProtocolTargetRule {
        func check(_ item: StrictCareProtocolTarget) -> [String]
    }

    final class StrictCareProtocolTargetAllowedCodeRule: StrictCareProtocolTargetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StrictCareProtocolTarget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is too long"]
            }
            return []
        }
    }

    final class StrictCareProtocolTargetLabelLengthRule: StrictCareProtocolTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictCareProtocolTarget) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictCareProtocolTargetCodeLengthRule: StrictCareProtocolTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictCareProtocolTarget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictCareProtocolTargetRequiredCodeRule: StrictCareProtocolTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictCareProtocolTarget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a strict care protocol target.
    final class StrictCareProtocolTargetValidator {
        var rules: [any StrictCareProtocolTargetRule]

        init(rules: [any StrictCareProtocolTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictCareProtocolTarget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictCareProtocolTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictCareProtocolTarget]) -> [String: [String]] {
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

    static func defaultStrictCareProtocolTargetValidator() -> StrictCareProtocolTargetValidator {
        return StrictCareProtocolTargetValidator(
            rules: [
                StrictCareProtocolTargetAllowedCodeRule(allowed: ["global", "primary", "primary"]),
                StrictCareProtocolTargetLabelLengthRule(maxLength: 16),
                StrictCareProtocolTargetCodeLengthRule(maxLength: 3600),
                StrictCareProtocolTargetRequiredCodeRule(message: "strict care protocol target needs an entry"),
            ]
        )
    }
}
