import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a isolation manifest must pass. Check returns its problems, or none.
    protocol IsolationManifestRule {
        func check(_ item: IsolationManifest) -> [String]
    }

    final class IsolationManifestDiscountRangeRule: IsolationManifestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: IsolationManifest) -> [String] {
            let value = item.discount
            var problems: [String] = []
            if value < min {
                problems.append("discount \(value) is below \(min)")
            }
            if value > max {
                problems.append("discount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class IsolationManifestCodeLengthRule: IsolationManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: IsolationManifest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class IsolationManifestAllowedCodeRule: IsolationManifestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: IsolationManifest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is too long"]
            }
            return []
        }
    }

    final class IsolationManifestRequiredLabelRule: IsolationManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: IsolationManifest) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class IsolationManifestRequiredCodeRule: IsolationManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: IsolationManifest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class IsolationManifestBudgetRangeRule: IsolationManifestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: IsolationManifest) -> [String] {
            let value = item.budget
            var problems: [String] = []
            if value < min {
                problems.append("budget \(value) is below \(min)")
            }
            if value > max {
                problems.append("budget \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a isolation manifest.
    final class IsolationManifestValidator {
        var rules: [any IsolationManifestRule]

        init(rules: [any IsolationManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: IsolationManifest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: IsolationManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [IsolationManifest]) -> [String: [String]] {
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

    static func defaultIsolationManifestValidator() -> IsolationManifestValidator {
        return IsolationManifestValidator(
            rules: [
                IsolationManifestDiscountRangeRule(min: 1.7, max: 2497.4),
                IsolationManifestCodeLengthRule(maxLength: 1000),
                IsolationManifestAllowedCodeRule(allowed: ["regional", "fallback"]),
                IsolationManifestRequiredLabelRule(message: "isolation manifest needs an entry"),
                IsolationManifestRequiredCodeRule(message: "isolation manifest needs an entry"),
                IsolationManifestBudgetRangeRule(min: 7.4, max: 3947.1),
            ]
        )
    }
}
