import AcmePlatform
import Foundation

extension Labs {
    /// A rule a batched accession notice must pass. Check returns its problems, or none.
    protocol BatchedAccessionNoticeRule {
        func check(_ item: BatchedAccessionNotice) -> [String]
    }

    final class BatchedAccessionNoticeRequiredNotesRule: BatchedAccessionNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedAccessionNotice) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedAccessionNoticeCeilingRangeRule: BatchedAccessionNoticeRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedAccessionNotice) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BatchedAccessionNoticeRequiredNameRule: BatchedAccessionNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedAccessionNotice) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedAccessionNoticeCodePrefixRule: BatchedAccessionNoticeRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BatchedAccessionNotice) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched accession notice.
    final class BatchedAccessionNoticeValidator {
        var rules: [any BatchedAccessionNoticeRule]

        init(rules: [any BatchedAccessionNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedAccessionNotice) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedAccessionNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedAccessionNotice]) -> [String: [String]] {
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

    static func defaultBatchedAccessionNoticeValidator() -> BatchedAccessionNoticeValidator {
        return BatchedAccessionNoticeValidator(
            rules: [
                BatchedAccessionNoticeRequiredNotesRule(message: "batched accession notice needs this field"),
                BatchedAccessionNoticeCeilingRangeRule(min: 7.2, max: 1028.1),
                BatchedAccessionNoticeRequiredNameRule(message: "batched accession notice needs this field"),
                BatchedAccessionNoticeCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
