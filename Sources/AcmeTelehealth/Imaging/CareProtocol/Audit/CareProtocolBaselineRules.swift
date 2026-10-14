import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a care protocol baseline must pass. Check returns its problems, or none.
    protocol CareProtocolBaselineRule {
        func check(_ item: CareProtocolBaseline) -> [String]
    }

    final class CareProtocolBaselineNameLengthRule: CareProtocolBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolBaseline) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolBaselineRequiredPayerRule: CareProtocolBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolBaseline) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareProtocolBaselineActiveGuardRule: CareProtocolBaselineRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: CareProtocolBaseline) -> [String] {
            if item.active && (item.minimum > limit) {
                return ["minimum \(item.minimum) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class CareProtocolBaselineCodeLengthRule: CareProtocolBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolBaseline) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolBaselineSpecialtyLengthRule: CareProtocolBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolBaseline) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a care protocol baseline.
    final class CareProtocolBaselineValidator {
        var rules: [any CareProtocolBaselineRule]

        init(rules: [any CareProtocolBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: CareProtocolBaseline) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CareProtocolBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareProtocolBaseline]) -> [String: [String]] {
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

    static func defaultCareProtocolBaselineValidator() -> CareProtocolBaselineValidator {
        return CareProtocolBaselineValidator(
            rules: [
                CareProtocolBaselineNameLengthRule(maxLength: 255),
                CareProtocolBaselineRequiredPayerRule(message: "care protocol baseline needs this field"),
                CareProtocolBaselineActiveGuardRule(limit: 4.7),
                CareProtocolBaselineCodeLengthRule(maxLength: 1000),
                CareProtocolBaselineSpecialtyLengthRule(maxLength: 16),
            ]
        )
    }
}
