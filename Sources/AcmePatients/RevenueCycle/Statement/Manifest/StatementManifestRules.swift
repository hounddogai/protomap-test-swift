import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a statement manifest must pass. Check returns its problems, or none.
    protocol StatementManifestRule {
        func check(_ item: StatementManifest) -> [String]
    }

    final class StatementManifestRequiredCodeRule: StatementManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StatementManifest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StatementManifestLabelLengthRule: StatementManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StatementManifest) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StatementManifestVisitMinutesRangeRule: StatementManifestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StatementManifest) -> [String] {
            let value = item.visitMinutes
            if value < min || value > max {
                return ["visit minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StatementManifestRequiredUnitRule: StatementManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StatementManifest) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StatementManifestRequiredPhoneRule: StatementManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StatementManifest) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StatementManifestPhoneLengthRule: StatementManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StatementManifest) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a statement manifest.
    final class StatementManifestValidator {
        var rules: [any StatementManifestRule]

        init(rules: [any StatementManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: StatementManifest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StatementManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StatementManifest]) -> [String: [String]] {
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

    static func defaultStatementManifestValidator() -> StatementManifestValidator {
        return StatementManifestValidator(
            rules: [
                StatementManifestRequiredCodeRule(message: "statement manifest needs a value"),
                StatementManifestLabelLengthRule(maxLength: 120),
                StatementManifestVisitMinutesRangeRule(min: 80, max: 86400),
                StatementManifestRequiredUnitRule(message: "statement manifest needs an entry"),
                StatementManifestRequiredPhoneRule(message: "statement manifest needs an entry"),
                StatementManifestPhoneLengthRule(maxLength: 80),
            ]
        )
    }
}
