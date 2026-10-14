import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a lenient program group must pass. Check returns its problems, or none.
    protocol LenientProgramGroupRule {
        func check(_ item: LenientProgramGroup) -> [String]
    }

    final class LenientProgramGroupCodePrefixRule: LenientProgramGroupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LenientProgramGroup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LenientProgramGroupCodeLengthRule: LenientProgramGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientProgramGroup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientProgramGroupLabelLengthRule: LenientProgramGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientProgramGroup) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient program group.
    final class LenientProgramGroupValidator {
        var rules: [any LenientProgramGroupRule]

        init(rules: [any LenientProgramGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientProgramGroup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientProgramGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientProgramGroup]) -> [String: [String]] {
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

    static func defaultLenientProgramGroupValidator() -> LenientProgramGroupValidator {
        return LenientProgramGroupValidator(
            rules: [
                LenientProgramGroupCodePrefixRule(prefix: "Q"),
                LenientProgramGroupCodeLengthRule(maxLength: 3600),
                LenientProgramGroupLabelLengthRule(maxLength: 64),
            ]
        )
    }
}
