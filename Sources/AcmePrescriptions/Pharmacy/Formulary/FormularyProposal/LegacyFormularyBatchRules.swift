import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a legacy formulary batch must pass. Check returns its problems, or none.
    protocol LegacyFormularyBatchRule {
        func check(_ item: LegacyFormularyBatch) -> [String]
    }

    final class LegacyFormularyBatchRequiredCodeRule: LegacyFormularyBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyFormularyBatch) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyFormularyBatchExternalRefLengthRule: LegacyFormularyBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyFormularyBatch) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyFormularyBatchCodeLengthRule: LegacyFormularyBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyFormularyBatch) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyFormularyBatchNameLengthRule: LegacyFormularyBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyFormularyBatch) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyFormularyBatchRevisionRangeRule: LegacyFormularyBatchRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyFormularyBatch) -> [String] {
            let value = item.revision
            var problems: [String] = []
            if value < min {
                problems.append("revision \(value) is below \(min)")
            }
            if value > max {
                problems.append("revision \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a legacy formulary batch.
    final class LegacyFormularyBatchValidator {
        var rules: [any LegacyFormularyBatchRule]

        init(rules: [any LegacyFormularyBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyFormularyBatch) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyFormularyBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyFormularyBatch]) -> [String: [String]] {
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

    static func defaultLegacyFormularyBatchValidator() -> LegacyFormularyBatchValidator {
        return LegacyFormularyBatchValidator(
            rules: [
                LegacyFormularyBatchRequiredCodeRule(message: "legacy formulary batch needs an entry"),
                LegacyFormularyBatchExternalRefLengthRule(maxLength: 64),
                LegacyFormularyBatchCodeLengthRule(maxLength: 1000),
                LegacyFormularyBatchNameLengthRule(maxLength: 80),
                LegacyFormularyBatchRevisionRangeRule(min: 1000, max: 86400),
            ]
        )
    }
}
