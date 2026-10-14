import AcmePlatform
import Foundation

extension Labs {
    /// A rule a pending result baseline must pass. Check returns its problems, or none.
    protocol PendingResultBaselineRule {
        func check(_ item: PendingResultBaseline) -> [String]
    }

    final class PendingResultBaselineRequiredNameRule: PendingResultBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingResultBaseline) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingResultBaselineRequiredLabelRule: PendingResultBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingResultBaseline) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingResultBaselineNameLengthRule: PendingResultBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingResultBaseline) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingResultBaselineLabelLengthRule: PendingResultBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingResultBaseline) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingResultBaselineAllowedCodeRule: PendingResultBaselineRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PendingResultBaseline) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is blocked"]
            }
            return []
        }
    }

    final class PendingResultBaselineRequiredCodeRule: PendingResultBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingResultBaseline) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a pending result baseline.
    final class PendingResultBaselineValidator {
        var rules: [any PendingResultBaselineRule]

        init(rules: [any PendingResultBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingResultBaseline) -> [String] {
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

        func requireValid(_ item: PendingResultBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingResultBaseline]) -> [String: [String]] {
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

    static func defaultPendingResultBaselineValidator() -> PendingResultBaselineValidator {
        return PendingResultBaselineValidator(
            rules: [
                PendingResultBaselineRequiredNameRule(message: "pending result baseline needs this field"),
                PendingResultBaselineRequiredLabelRule(message: "pending result baseline needs this field"),
                PendingResultBaselineNameLengthRule(maxLength: 86400),
                PendingResultBaselineLabelLengthRule(maxLength: 16),
                PendingResultBaselineAllowedCodeRule(allowed: ["tiered", "default"]),
                PendingResultBaselineRequiredCodeRule(message: "pending result baseline needs this field"),
            ]
        )
    }
}
