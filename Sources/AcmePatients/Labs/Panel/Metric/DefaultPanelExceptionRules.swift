import AcmePlatform
import Foundation

extension Labs {
    /// A rule a default panel exception must pass. Check returns its problems, or none.
    protocol DefaultPanelExceptionRule {
        func check(_ item: DefaultPanelException) -> [String]
    }

    final class DefaultPanelExceptionNotesLengthRule: DefaultPanelExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultPanelException) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultPanelExceptionCodeLengthRule: DefaultPanelExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultPanelException) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultPanelExceptionExpiresAtRangeRule: DefaultPanelExceptionRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultPanelException) -> [String] {
            let value = item.expiresAt
            var problems: [String] = []
            if value < min {
                problems.append("expires at \(value) is below \(min)")
            }
            if value > max {
                problems.append("expires at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DefaultPanelExceptionRevisionRangeRule: DefaultPanelExceptionRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultPanelException) -> [String] {
            let value = item.revision
            if value < min || value > max {
                return ["revision \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultPanelExceptionAllowedCodeRule: DefaultPanelExceptionRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DefaultPanelException) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is expired"]
            }
            return []
        }
    }

    final class DefaultPanelExceptionMarginRangeRule: DefaultPanelExceptionRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultPanelException) -> [String] {
            let value = item.margin
            if value < min || value > max {
                return ["margin \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a default panel exception.
    final class DefaultPanelExceptionValidator {
        var rules: [any DefaultPanelExceptionRule]

        init(rules: [any DefaultPanelExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultPanelException) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultPanelException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultPanelException]) -> [String: [String]] {
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

    static func defaultDefaultPanelExceptionValidator() -> DefaultPanelExceptionValidator {
        return DefaultPanelExceptionValidator(
            rules: [
                DefaultPanelExceptionNotesLengthRule(maxLength: 16),
                DefaultPanelExceptionCodeLengthRule(maxLength: 16),
                DefaultPanelExceptionExpiresAtRangeRule(min: 255, max: 3600),
                DefaultPanelExceptionRevisionRangeRule(min: 16, max: 80),
                DefaultPanelExceptionAllowedCodeRule(allowed: ["adaptive"]),
                DefaultPanelExceptionMarginRangeRule(min: 3.2, max: 4974.1),
            ]
        )
    }
}
