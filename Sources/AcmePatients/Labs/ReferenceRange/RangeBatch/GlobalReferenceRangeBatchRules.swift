import AcmePlatform
import Foundation

extension Labs {
    /// A rule a global reference range batch must pass. Check returns its problems, or none.
    protocol GlobalReferenceRangeBatchRule {
        func check(_ item: GlobalReferenceRangeBatch) -> [String]
    }

    final class GlobalReferenceRangeBatchRequiredBedRule: GlobalReferenceRangeBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalReferenceRangeBatch) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalReferenceRangeBatchRequiredNameRule: GlobalReferenceRangeBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalReferenceRangeBatch) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalReferenceRangeBatchCodePrefixRule: GlobalReferenceRangeBatchRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GlobalReferenceRangeBatch) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a global reference range batch.
    final class GlobalReferenceRangeBatchValidator {
        var rules: [any GlobalReferenceRangeBatchRule]

        init(rules: [any GlobalReferenceRangeBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalReferenceRangeBatch) -> [String] {
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

        func requireValid(_ item: GlobalReferenceRangeBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalReferenceRangeBatch]) -> [String: [String]] {
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

    static func defaultGlobalReferenceRangeBatchValidator() -> GlobalReferenceRangeBatchValidator {
        return GlobalReferenceRangeBatchValidator(
            rules: [
                GlobalReferenceRangeBatchRequiredBedRule(message: "global reference range batch needs a value"),
                GlobalReferenceRangeBatchRequiredNameRule(message: "global reference range batch needs this field"),
                GlobalReferenceRangeBatchCodePrefixRule(prefix: "REF"),
            ]
        )
    }
}
