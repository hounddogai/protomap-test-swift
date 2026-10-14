import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a care protocol target must pass. Check returns its problems, or none.
    protocol CareProtocolTargetRule {
        func check(_ item: CareProtocolTarget) -> [String]
    }

    final class CareProtocolTargetRateRangeRule: CareProtocolTargetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolTarget) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CareProtocolTargetProcedureCodeLengthRule: CareProtocolTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolTarget) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolTargetRequiredTitleRule: CareProtocolTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolTarget) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a care protocol target.
    final class CareProtocolTargetValidator {
        var rules: [any CareProtocolTargetRule]

        init(rules: [any CareProtocolTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: CareProtocolTarget) -> [String] {
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

        func requireValid(_ item: CareProtocolTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareProtocolTarget]) -> [String: [String]] {
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

    static func defaultCareProtocolTargetValidator() -> CareProtocolTargetValidator {
        return CareProtocolTargetValidator(
            rules: [
                CareProtocolTargetRateRangeRule(min: 0.1, max: 1849.1),
                CareProtocolTargetProcedureCodeLengthRule(maxLength: 120),
                CareProtocolTargetRequiredTitleRule(message: "care protocol target needs a value"),
            ]
        )
    }
}
