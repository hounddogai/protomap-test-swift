import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a capped alert window must pass. Check returns its problems, or none.
    protocol CappedAlertWindowRule {
        func check(_ item: CappedAlertWindow) -> [String]
    }

    final class CappedAlertWindowLabelLengthRule: CappedAlertWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedAlertWindow) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedAlertWindowAllowedLabelRule: CappedAlertWindowRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CappedAlertWindow) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is missing"]
            }
            return []
        }
    }

    final class CappedAlertWindowCodePrefixRule: CappedAlertWindowRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedAlertWindow) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped alert window.
    final class CappedAlertWindowValidator {
        var rules: [any CappedAlertWindowRule]

        init(rules: [any CappedAlertWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedAlertWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedAlertWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedAlertWindow]) -> [String: [String]] {
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

    static func defaultCappedAlertWindowValidator() -> CappedAlertWindowValidator {
        return CappedAlertWindowValidator(
            rules: [
                CappedAlertWindowLabelLengthRule(maxLength: 16),
                CappedAlertWindowAllowedLabelRule(allowed: []),
                CappedAlertWindowCodePrefixRule(prefix: "REF"),
            ]
        )
    }
}
