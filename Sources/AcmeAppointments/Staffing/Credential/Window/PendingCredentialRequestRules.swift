import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a pending credential request must pass. Check returns its problems, or none.
    protocol PendingCredentialRequestRule {
        func check(_ item: PendingCredentialRequest) -> [String]
    }

    final class PendingCredentialRequestLabelLengthRule: PendingCredentialRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingCredentialRequest) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingCredentialRequestCodeLengthRule: PendingCredentialRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingCredentialRequest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingCredentialRequestRequiredLabelRule: PendingCredentialRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingCredentialRequest) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingCredentialRequestBatchSizeRangeRule: PendingCredentialRequestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingCredentialRequest) -> [String] {
            let value = item.batchSize
            var problems: [String] = []
            if value < min {
                problems.append("batch size \(value) is below \(min)")
            }
            if value > max {
                problems.append("batch size \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PendingCredentialRequestRequiredCurrencyRule: PendingCredentialRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingCredentialRequest) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a pending credential request.
    final class PendingCredentialRequestValidator {
        var rules: [any PendingCredentialRequestRule]

        init(rules: [any PendingCredentialRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingCredentialRequest) -> [String] {
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

        func requireValid(_ item: PendingCredentialRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingCredentialRequest]) -> [String: [String]] {
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

    static func defaultPendingCredentialRequestValidator() -> PendingCredentialRequestValidator {
        return PendingCredentialRequestValidator(
            rules: [
                PendingCredentialRequestLabelLengthRule(maxLength: 86400),
                PendingCredentialRequestCodeLengthRule(maxLength: 86400),
                PendingCredentialRequestRequiredLabelRule(message: "pending credential request needs a value"),
                PendingCredentialRequestBatchSizeRangeRule(min: 16, max: 16),
                PendingCredentialRequestRequiredCurrencyRule(message: "pending credential request needs this field"),
            ]
        )
    }
}
