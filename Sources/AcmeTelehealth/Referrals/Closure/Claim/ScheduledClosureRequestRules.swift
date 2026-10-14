import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a scheduled closure request must pass. Check returns its problems, or none.
    protocol ScheduledClosureRequestRule {
        func check(_ item: ScheduledClosureRequest) -> [String]
    }

    final class ScheduledClosureRequestDiagnosisCodeLengthRule: ScheduledClosureRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledClosureRequest) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledClosureRequestCodePrefixRule: ScheduledClosureRequestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledClosureRequest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ScheduledClosureRequestRequiredCountryRule: ScheduledClosureRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledClosureRequest) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled closure request.
    final class ScheduledClosureRequestValidator {
        var rules: [any ScheduledClosureRequestRule]

        init(rules: [any ScheduledClosureRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledClosureRequest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledClosureRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledClosureRequest]) -> [String: [String]] {
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

    static func defaultScheduledClosureRequestValidator() -> ScheduledClosureRequestValidator {
        return ScheduledClosureRequestValidator(
            rules: [
                ScheduledClosureRequestDiagnosisCodeLengthRule(maxLength: 64),
                ScheduledClosureRequestCodePrefixRule(prefix: "OPS"),
                ScheduledClosureRequestRequiredCountryRule(message: "scheduled closure request needs a value"),
            ]
        )
    }
}
