import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a default read baseline must pass. Check returns its problems, or none.
    protocol DefaultReadBaselineRule {
        func check(_ item: DefaultReadBaseline) -> [String]
    }

    final class DefaultReadBaselineAllowedNameRule: DefaultReadBaselineRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DefaultReadBaseline) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is too long"]
            }
            return []
        }
    }

    final class DefaultReadBaselineApprovedGuardRule: DefaultReadBaselineRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: DefaultReadBaseline) -> [String] {
            if item.approved && (item.maximum > limit) {
                return ["maximum \(item.maximum) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class DefaultReadBaselineRequiredNameRule: DefaultReadBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultReadBaseline) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultReadBaselineRequiredCodeRule: DefaultReadBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultReadBaseline) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultReadBaselineCopayRangeRule: DefaultReadBaselineRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultReadBaseline) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultReadBaselineNameLengthRule: DefaultReadBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultReadBaseline) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a default read baseline.
    final class DefaultReadBaselineValidator {
        var rules: [any DefaultReadBaselineRule]

        init(rules: [any DefaultReadBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultReadBaseline) -> [String] {
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

        func requireValid(_ item: DefaultReadBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultReadBaseline]) -> [String: [String]] {
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

    static func defaultDefaultReadBaselineValidator() -> DefaultReadBaselineValidator {
        return DefaultReadBaselineValidator(
            rules: [
                DefaultReadBaselineAllowedNameRule(allowed: ["primary", "pending"]),
                DefaultReadBaselineApprovedGuardRule(limit: 8.2),
                DefaultReadBaselineRequiredNameRule(message: "default read baseline needs this field"),
                DefaultReadBaselineRequiredCodeRule(message: "default read baseline needs this field"),
                DefaultReadBaselineCopayRangeRule(min: 6.8, max: 3214.0),
                DefaultReadBaselineNameLengthRule(maxLength: 3600),
            ]
        )
    }
}
