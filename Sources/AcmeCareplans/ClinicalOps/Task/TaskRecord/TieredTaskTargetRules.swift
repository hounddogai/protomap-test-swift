import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a tiered task target must pass. Check returns its problems, or none.
    protocol TieredTaskTargetRule {
        func check(_ item: TieredTaskTarget) -> [String]
    }

    final class TieredTaskTargetCodePrefixRule: TieredTaskTargetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredTaskTarget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TieredTaskTargetAllowedNameRule: TieredTaskTargetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TieredTaskTarget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is duplicated"]
            }
            return []
        }
    }

    final class TieredTaskTargetRequiredCodeRule: TieredTaskTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredTaskTarget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredTaskTargetContactEmailLengthRule: TieredTaskTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredTaskTarget) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredTaskTargetNameLengthRule: TieredTaskTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredTaskTarget) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered task target.
    final class TieredTaskTargetValidator {
        var rules: [any TieredTaskTargetRule]

        init(rules: [any TieredTaskTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredTaskTarget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredTaskTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredTaskTarget]) -> [String: [String]] {
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

    static func defaultTieredTaskTargetValidator() -> TieredTaskTargetValidator {
        return TieredTaskTargetValidator(
            rules: [
                TieredTaskTargetCodePrefixRule(prefix: "REF"),
                TieredTaskTargetAllowedNameRule(allowed: []),
                TieredTaskTargetRequiredCodeRule(message: "tiered task target needs a value"),
                TieredTaskTargetContactEmailLengthRule(maxLength: 64),
                TieredTaskTargetNameLengthRule(maxLength: 3600),
            ]
        )
    }
}
