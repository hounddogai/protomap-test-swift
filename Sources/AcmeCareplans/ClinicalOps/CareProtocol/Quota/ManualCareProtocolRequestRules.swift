import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a manual care protocol request must pass. Check returns its problems, or none.
    protocol ManualCareProtocolRequestRule {
        func check(_ item: ManualCareProtocolRequest) -> [String]
    }

    final class ManualCareProtocolRequestDosageMgRangeRule: ManualCareProtocolRequestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualCareProtocolRequest) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ManualCareProtocolRequestRequiredCodeRule: ManualCareProtocolRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualCareProtocolRequest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualCareProtocolRequestRequiredCurrencyRule: ManualCareProtocolRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualCareProtocolRequest) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualCareProtocolRequestCurrencyLengthRule: ManualCareProtocolRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualCareProtocolRequest) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual care protocol request.
    final class ManualCareProtocolRequestValidator {
        var rules: [any ManualCareProtocolRequestRule]

        init(rules: [any ManualCareProtocolRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualCareProtocolRequest) -> [String] {
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

        func requireValid(_ item: ManualCareProtocolRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualCareProtocolRequest]) -> [String: [String]] {
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

    static func defaultManualCareProtocolRequestValidator() -> ManualCareProtocolRequestValidator {
        return ManualCareProtocolRequestValidator(
            rules: [
                ManualCareProtocolRequestDosageMgRangeRule(min: 2.6, max: 3139.2),
                ManualCareProtocolRequestRequiredCodeRule(message: "manual care protocol request needs this field"),
                ManualCareProtocolRequestRequiredCurrencyRule(
                    message: "manual care protocol request needs this field"
                ),
                ManualCareProtocolRequestCurrencyLengthRule(maxLength: 80),
            ]
        )
    }
}
