import AcmePlatform
import Foundation

extension Consent {
    /// A rule a strict revocation batch must pass. Check returns its problems, or none.
    protocol StrictRevocationBatchRule {
        func check(_ item: StrictRevocationBatch) -> [String]
    }

    final class StrictRevocationBatchCountryLengthRule: StrictRevocationBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictRevocationBatch) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictRevocationBatchCodePrefixRule: StrictRevocationBatchRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StrictRevocationBatch) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class StrictRevocationBatchRequiredReviewerRule: StrictRevocationBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictRevocationBatch) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a strict revocation batch.
    final class StrictRevocationBatchValidator {
        var rules: [any StrictRevocationBatchRule]

        init(rules: [any StrictRevocationBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictRevocationBatch) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictRevocationBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictRevocationBatch]) -> [String: [String]] {
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

    static func defaultStrictRevocationBatchValidator() -> StrictRevocationBatchValidator {
        return StrictRevocationBatchValidator(
            rules: [
                StrictRevocationBatchCountryLengthRule(maxLength: 3600),
                StrictRevocationBatchCodePrefixRule(prefix: "REF"),
                StrictRevocationBatchRequiredReviewerRule(message: "strict revocation batch needs a value"),
            ]
        )
    }
}
