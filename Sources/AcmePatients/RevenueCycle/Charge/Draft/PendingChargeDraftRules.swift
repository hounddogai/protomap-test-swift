import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a pending charge draft must pass. Check returns its problems, or none.
    protocol PendingChargeDraftRule {
        func check(_ item: PendingChargeDraft) -> [String]
    }

    final class PendingChargeDraftRequiredNameRule: PendingChargeDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingChargeDraft) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingChargeDraftCategoryLengthRule: PendingChargeDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingChargeDraft) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingChargeDraftCodePrefixRule: PendingChargeDraftRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PendingChargeDraft) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PendingChargeDraftCodeLengthRule: PendingChargeDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingChargeDraft) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending charge draft.
    final class PendingChargeDraftValidator {
        var rules: [any PendingChargeDraftRule]

        init(rules: [any PendingChargeDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingChargeDraft) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingChargeDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingChargeDraft]) -> [String: [String]] {
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

    static func defaultPendingChargeDraftValidator() -> PendingChargeDraftValidator {
        return PendingChargeDraftValidator(
            rules: [
                PendingChargeDraftRequiredNameRule(message: "pending charge draft needs this field"),
                PendingChargeDraftCategoryLengthRule(maxLength: 1000),
                PendingChargeDraftCodePrefixRule(prefix: "Q"),
                PendingChargeDraftCodeLengthRule(maxLength: 255),
            ]
        )
    }
}
