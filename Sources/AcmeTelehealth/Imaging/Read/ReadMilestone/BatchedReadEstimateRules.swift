import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a batched read estimate must pass. Check returns its problems, or none.
    protocol BatchedReadEstimateRule {
        func check(_ item: BatchedReadEstimate) -> [String]
    }

    final class BatchedReadEstimateCodePrefixRule: BatchedReadEstimateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BatchedReadEstimate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class BatchedReadEstimateSourceLengthRule: BatchedReadEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedReadEstimate) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedReadEstimateRequiredCodeRule: BatchedReadEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedReadEstimate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a batched read estimate.
    final class BatchedReadEstimateValidator {
        var rules: [any BatchedReadEstimateRule]

        init(rules: [any BatchedReadEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedReadEstimate) -> [String] {
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

        func requireValid(_ item: BatchedReadEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedReadEstimate]) -> [String: [String]] {
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

    static func defaultBatchedReadEstimateValidator() -> BatchedReadEstimateValidator {
        return BatchedReadEstimateValidator(
            rules: [
                BatchedReadEstimateCodePrefixRule(prefix: "X"),
                BatchedReadEstimateSourceLengthRule(maxLength: 255),
                BatchedReadEstimateRequiredCodeRule(message: "batched read estimate needs a value"),
            ]
        )
    }
}
