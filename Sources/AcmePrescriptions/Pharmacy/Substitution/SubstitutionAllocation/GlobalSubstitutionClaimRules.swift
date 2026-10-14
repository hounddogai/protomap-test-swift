import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a global substitution claim must pass. Check returns its problems, or none.
    protocol GlobalSubstitutionClaimRule {
        func check(_ item: GlobalSubstitutionClaim) -> [String]
    }

    final class GlobalSubstitutionClaimRequiredCodeRule: GlobalSubstitutionClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalSubstitutionClaim) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalSubstitutionClaimAllowedSourceRule: GlobalSubstitutionClaimRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GlobalSubstitutionClaim) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.source)) {
                return ["source \(item.source) is below minimum"]
            }
            return []
        }
    }

    final class GlobalSubstitutionClaimRequiredChannelRule: GlobalSubstitutionClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalSubstitutionClaim) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalSubstitutionClaimTitleLengthRule: GlobalSubstitutionClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalSubstitutionClaim) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalSubstitutionClaimSourceLengthRule: GlobalSubstitutionClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalSubstitutionClaim) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalSubstitutionClaimRequiredSourceRule: GlobalSubstitutionClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalSubstitutionClaim) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a global substitution claim.
    final class GlobalSubstitutionClaimValidator {
        var rules: [any GlobalSubstitutionClaimRule]

        init(rules: [any GlobalSubstitutionClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalSubstitutionClaim) -> [String] {
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

        func requireValid(_ item: GlobalSubstitutionClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalSubstitutionClaim]) -> [String: [String]] {
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

    static func defaultGlobalSubstitutionClaimValidator() -> GlobalSubstitutionClaimValidator {
        return GlobalSubstitutionClaimValidator(
            rules: [
                GlobalSubstitutionClaimRequiredCodeRule(message: "global substitution claim needs this field"),
                GlobalSubstitutionClaimAllowedSourceRule(allowed: ["global"]),
                GlobalSubstitutionClaimRequiredChannelRule(message: "global substitution claim needs this field"),
                GlobalSubstitutionClaimTitleLengthRule(maxLength: 1000),
                GlobalSubstitutionClaimSourceLengthRule(maxLength: 16),
                GlobalSubstitutionClaimRequiredSourceRule(message: "global substitution claim needs an entry"),
            ]
        )
    }
}
