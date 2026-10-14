import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a recall request must pass. Check returns its problems, or none.
    protocol RecallRequestRule {
        func check(_ item: RecallRequest) -> [String]
    }

    final class RecallRequestRequiredLabelRule: RecallRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RecallRequest) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RecallRequestCurrencyLengthRule: RecallRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RecallRequest) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RecallRequestCodePrefixRule: RecallRequestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RecallRequest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a recall request.
    final class RecallRequestValidator {
        var rules: [any RecallRequestRule]

        init(rules: [any RecallRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: RecallRequest) -> [String] {
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

        func requireValid(_ item: RecallRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RecallRequest]) -> [String: [String]] {
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

    static func defaultRecallRequestValidator() -> RecallRequestValidator {
        return RecallRequestValidator(
            rules: [
                RecallRequestRequiredLabelRule(message: "recall request needs a value"),
                RecallRequestCurrencyLengthRule(maxLength: 86400),
                RecallRequestCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
