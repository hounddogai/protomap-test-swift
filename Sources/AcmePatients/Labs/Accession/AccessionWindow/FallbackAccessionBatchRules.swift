import AcmePlatform
import Foundation

extension Labs {
    /// A rule a fallback accession batch must pass. Check returns its problems, or none.
    protocol FallbackAccessionBatchRule {
        func check(_ item: FallbackAccessionBatch) -> [String]
    }

    final class FallbackAccessionBatchTitleLengthRule: FallbackAccessionBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackAccessionBatch) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackAccessionBatchRequiredTitleRule: FallbackAccessionBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackAccessionBatch) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackAccessionBatchRequiredCodeRule: FallbackAccessionBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackAccessionBatch) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackAccessionBatchAllowedCodeRule: FallbackAccessionBatchRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FallbackAccessionBatch) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is below minimum"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback accession batch.
    final class FallbackAccessionBatchValidator {
        var rules: [any FallbackAccessionBatchRule]

        init(rules: [any FallbackAccessionBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackAccessionBatch) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackAccessionBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackAccessionBatch]) -> [String: [String]] {
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

    static func defaultFallbackAccessionBatchValidator() -> FallbackAccessionBatchValidator {
        return FallbackAccessionBatchValidator(
            rules: [
                FallbackAccessionBatchTitleLengthRule(maxLength: 16),
                FallbackAccessionBatchRequiredTitleRule(message: "fallback accession batch needs an entry"),
                FallbackAccessionBatchRequiredCodeRule(message: "fallback accession batch needs this field"),
                FallbackAccessionBatchAllowedCodeRule(allowed: ["strict"]),
            ]
        )
    }
}
