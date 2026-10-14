import AcmePlatform
import Foundation

extension Labs {
    /// A rule a reference range estimate must pass. Check returns its problems, or none.
    protocol ReferenceRangeEstimateRule {
        func check(_ item: ReferenceRangeEstimate) -> [String]
    }

    final class ReferenceRangeEstimateCodeLengthRule: ReferenceRangeEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferenceRangeEstimate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferenceRangeEstimateRequiredCodeRule: ReferenceRangeEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferenceRangeEstimate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferenceRangeEstimateTitleLengthRule: ReferenceRangeEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferenceRangeEstimate) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferenceRangeEstimateActiveGuardRule: ReferenceRangeEstimateRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: ReferenceRangeEstimate) -> [String] {
            if item.active && (item.amount > limit) {
                return ["amount \(item.amount) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class ReferenceRangeEstimateCodePrefixRule: ReferenceRangeEstimateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ReferenceRangeEstimate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ReferenceRangeEstimateRequiredTitleRule: ReferenceRangeEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferenceRangeEstimate) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a reference range estimate.
    final class ReferenceRangeEstimateValidator {
        var rules: [any ReferenceRangeEstimateRule]

        init(rules: [any ReferenceRangeEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferenceRangeEstimate) -> [String] {
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

        func requireValid(_ item: ReferenceRangeEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferenceRangeEstimate]) -> [String: [String]] {
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

    static func defaultReferenceRangeEstimateValidator() -> ReferenceRangeEstimateValidator {
        return ReferenceRangeEstimateValidator(
            rules: [
                ReferenceRangeEstimateCodeLengthRule(maxLength: 255),
                ReferenceRangeEstimateRequiredCodeRule(message: "reference range estimate needs this field"),
                ReferenceRangeEstimateTitleLengthRule(maxLength: 120),
                ReferenceRangeEstimateActiveGuardRule(limit: 7.9),
                ReferenceRangeEstimateCodePrefixRule(prefix: "ACM"),
                ReferenceRangeEstimateRequiredTitleRule(message: "reference range estimate needs a value"),
            ]
        )
    }
}
