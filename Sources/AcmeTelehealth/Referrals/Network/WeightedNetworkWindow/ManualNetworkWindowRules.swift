import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a manual network window must pass. Check returns its problems, or none.
    protocol ManualNetworkWindowRule {
        func check(_ item: ManualNetworkWindow) -> [String]
    }

    final class ManualNetworkWindowRequiredTitleRule: ManualNetworkWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualNetworkWindow) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualNetworkWindowCodePrefixRule: ManualNetworkWindowRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ManualNetworkWindow) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ManualNetworkWindowProcedureCodeLengthRule: ManualNetworkWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualNetworkWindow) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual network window.
    final class ManualNetworkWindowValidator {
        var rules: [any ManualNetworkWindowRule]

        init(rules: [any ManualNetworkWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualNetworkWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualNetworkWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualNetworkWindow]) -> [String: [String]] {
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

    static func defaultManualNetworkWindowValidator() -> ManualNetworkWindowValidator {
        return ManualNetworkWindowValidator(
            rules: [
                ManualNetworkWindowRequiredTitleRule(message: "manual network window needs this field"),
                ManualNetworkWindowCodePrefixRule(prefix: "REF"),
                ManualNetworkWindowProcedureCodeLengthRule(maxLength: 32),
            ]
        )
    }
}
