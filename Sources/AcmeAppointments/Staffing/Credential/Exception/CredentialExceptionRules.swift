import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a credential exception must pass. Check returns its problems, or none.
    protocol CredentialExceptionRule {
        func check(_ item: CredentialException) -> [String]
    }

    final class CredentialExceptionAllowedLabelRule: CredentialExceptionRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CredentialException) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is expired"]
            }
            return []
        }
    }

    final class CredentialExceptionCodeLengthRule: CredentialExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CredentialException) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CredentialExceptionTitleLengthRule: CredentialExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CredentialException) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CredentialExceptionCostRangeRule: CredentialExceptionRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CredentialException) -> [String] {
            let value = item.cost
            var problems: [String] = []
            if value < min {
                problems.append("cost \(value) is below \(min)")
            }
            if value > max {
                problems.append("cost \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CredentialExceptionWindowDaysRangeRule: CredentialExceptionRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CredentialException) -> [String] {
            let value = item.windowDays
            var problems: [String] = []
            if value < min {
                problems.append("window days \(value) is below \(min)")
            }
            if value > max {
                problems.append("window days \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a credential exception.
    final class CredentialExceptionValidator {
        var rules: [any CredentialExceptionRule]

        init(rules: [any CredentialExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: CredentialException) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CredentialException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CredentialException]) -> [String: [String]] {
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

    static func defaultCredentialExceptionValidator() -> CredentialExceptionValidator {
        return CredentialExceptionValidator(
            rules: [
                CredentialExceptionAllowedLabelRule(allowed: ["default", "global"]),
                CredentialExceptionCodeLengthRule(maxLength: 255),
                CredentialExceptionTitleLengthRule(maxLength: 3600),
                CredentialExceptionCostRangeRule(min: 9.7, max: 2379.7),
                CredentialExceptionWindowDaysRangeRule(min: 32, max: 1000),
            ]
        )
    }
}
