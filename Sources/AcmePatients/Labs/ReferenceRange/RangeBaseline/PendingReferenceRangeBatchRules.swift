import AcmePlatform
import Foundation

extension Labs {
    /// A rule a pending reference range batch must pass. Check returns its problems, or none.
    protocol PendingReferenceRangeBatchRule {
        func check(_ item: PendingReferenceRangeBatch) -> [String]
    }

    final class PendingReferenceRangeBatchVisibleGuardRule: PendingReferenceRangeBatchRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: PendingReferenceRangeBatch) -> [String] {
            if item.visible && (item.refills > limit) {
                return ["refills \(item.refills) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class PendingReferenceRangeBatchTitleLengthRule: PendingReferenceRangeBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingReferenceRangeBatch) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingReferenceRangeBatchCodePrefixRule: PendingReferenceRangeBatchRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PendingReferenceRangeBatch) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PendingReferenceRangeBatchRequiredCodeRule: PendingReferenceRangeBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingReferenceRangeBatch) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingReferenceRangeBatchCodeLengthRule: PendingReferenceRangeBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingReferenceRangeBatch) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingReferenceRangeBatchCategoryLengthRule: PendingReferenceRangeBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingReferenceRangeBatch) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending reference range batch.
    final class PendingReferenceRangeBatchValidator {
        var rules: [any PendingReferenceRangeBatchRule]

        init(rules: [any PendingReferenceRangeBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingReferenceRangeBatch) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingReferenceRangeBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingReferenceRangeBatch]) -> [String: [String]] {
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

    static func defaultPendingReferenceRangeBatchValidator() -> PendingReferenceRangeBatchValidator {
        return PendingReferenceRangeBatchValidator(
            rules: [
                PendingReferenceRangeBatchVisibleGuardRule(limit: 120),
                PendingReferenceRangeBatchTitleLengthRule(maxLength: 86400),
                PendingReferenceRangeBatchCodePrefixRule(prefix: "REF"),
                PendingReferenceRangeBatchRequiredCodeRule(message: "pending reference range batch needs an entry"),
                PendingReferenceRangeBatchCodeLengthRule(maxLength: 64),
                PendingReferenceRangeBatchCategoryLengthRule(maxLength: 86400),
            ]
        )
    }
}
