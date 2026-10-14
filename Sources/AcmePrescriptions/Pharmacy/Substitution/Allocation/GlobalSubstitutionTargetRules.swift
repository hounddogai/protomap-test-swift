import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a global substitution target must pass. Check returns its problems, or none.
    protocol GlobalSubstitutionTargetRule {
        func check(_ item: GlobalSubstitutionTarget) -> [String]
    }

    final class GlobalSubstitutionTargetReviewerLengthRule: GlobalSubstitutionTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalSubstitutionTarget) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalSubstitutionTargetRequiredCodeRule: GlobalSubstitutionTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalSubstitutionTarget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalSubstitutionTargetRequiredNameRule: GlobalSubstitutionTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalSubstitutionTarget) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalSubstitutionTargetSegmentLengthRule: GlobalSubstitutionTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalSubstitutionTarget) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalSubstitutionTargetAllowedCodeRule: GlobalSubstitutionTargetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GlobalSubstitutionTarget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is missing"]
            }
            return []
        }
    }

    /// Runs every rule of a global substitution target.
    final class GlobalSubstitutionTargetValidator {
        var rules: [any GlobalSubstitutionTargetRule]

        init(rules: [any GlobalSubstitutionTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalSubstitutionTarget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalSubstitutionTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalSubstitutionTarget]) -> [String: [String]] {
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

    static func defaultGlobalSubstitutionTargetValidator() -> GlobalSubstitutionTargetValidator {
        return GlobalSubstitutionTargetValidator(
            rules: [
                GlobalSubstitutionTargetReviewerLengthRule(maxLength: 64),
                GlobalSubstitutionTargetRequiredCodeRule(message: "global substitution target needs this field"),
                GlobalSubstitutionTargetRequiredNameRule(message: "global substitution target needs a value"),
                GlobalSubstitutionTargetSegmentLengthRule(maxLength: 86400),
                GlobalSubstitutionTargetAllowedCodeRule(allowed: ["seasonal", "fallback", "seasonal"]),
            ]
        )
    }
}
