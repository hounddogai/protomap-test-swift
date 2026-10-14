import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a lenient program window must pass. Check returns its problems, or none.
    protocol LenientProgramWindowRule {
        func check(_ item: LenientProgramWindow) -> [String]
    }

    final class LenientProgramWindowAllergyLengthRule: LenientProgramWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientProgramWindow) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientProgramWindowRequiredNameRule: LenientProgramWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientProgramWindow) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientProgramWindowCodePrefixRule: LenientProgramWindowRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LenientProgramWindow) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LenientProgramWindowCodeLengthRule: LenientProgramWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientProgramWindow) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientProgramWindowAllowedCodeRule: LenientProgramWindowRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LenientProgramWindow) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is stale"]
            }
            return []
        }
    }

    final class LenientProgramWindowNameLengthRule: LenientProgramWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientProgramWindow) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient program window.
    final class LenientProgramWindowValidator {
        var rules: [any LenientProgramWindowRule]

        init(rules: [any LenientProgramWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientProgramWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientProgramWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientProgramWindow]) -> [String: [String]] {
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

    static func defaultLenientProgramWindowValidator() -> LenientProgramWindowValidator {
        return LenientProgramWindowValidator(
            rules: [
                LenientProgramWindowAllergyLengthRule(maxLength: 255),
                LenientProgramWindowRequiredNameRule(message: "lenient program window needs an entry"),
                LenientProgramWindowCodePrefixRule(prefix: "X"),
                LenientProgramWindowCodeLengthRule(maxLength: 32),
                LenientProgramWindowAllowedCodeRule(allowed: []),
                LenientProgramWindowNameLengthRule(maxLength: 120),
            ]
        )
    }
}
