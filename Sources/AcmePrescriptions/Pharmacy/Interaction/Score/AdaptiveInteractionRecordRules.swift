import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a adaptive interaction record must pass. Check returns its problems, or none.
    protocol AdaptiveInteractionRecordRule {
        func check(_ item: AdaptiveInteractionRecord) -> [String]
    }

    final class AdaptiveInteractionRecordSummaryLengthRule: AdaptiveInteractionRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveInteractionRecord) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveInteractionRecordCodePrefixRule: AdaptiveInteractionRecordRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveInteractionRecord) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AdaptiveInteractionRecordRequiredCodeRule: AdaptiveInteractionRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveInteractionRecord) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive interaction record.
    final class AdaptiveInteractionRecordValidator {
        var rules: [any AdaptiveInteractionRecordRule]

        init(rules: [any AdaptiveInteractionRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveInteractionRecord) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveInteractionRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveInteractionRecord]) -> [String: [String]] {
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

    static func defaultAdaptiveInteractionRecordValidator() -> AdaptiveInteractionRecordValidator {
        return AdaptiveInteractionRecordValidator(
            rules: [
                AdaptiveInteractionRecordSummaryLengthRule(maxLength: 64),
                AdaptiveInteractionRecordCodePrefixRule(prefix: "OPS"),
                AdaptiveInteractionRecordRequiredCodeRule(message: "adaptive interaction record needs a value"),
            ]
        )
    }
}
