import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a slot review must pass. Check returns its problems, or none.
    protocol SlotReviewRule {
        func check(_ item: SlotReview) -> [String]
    }

    final class SlotReviewWardLengthRule: SlotReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SlotReview) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SlotReviewNameLengthRule: SlotReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SlotReview) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SlotReviewCodePrefixRule: SlotReviewRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SlotReview) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SlotReviewRequiredNameRule: SlotReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SlotReview) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SlotReviewRequiredCodeRule: SlotReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SlotReview) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SlotReviewCodeLengthRule: SlotReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SlotReview) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a slot review.
    final class SlotReviewValidator {
        var rules: [any SlotReviewRule]

        init(rules: [any SlotReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: SlotReview) -> [String] {
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

        func requireValid(_ item: SlotReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SlotReview]) -> [String: [String]] {
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

    static func defaultSlotReviewValidator() -> SlotReviewValidator {
        return SlotReviewValidator(
            rules: [
                SlotReviewWardLengthRule(maxLength: 1000),
                SlotReviewNameLengthRule(maxLength: 16),
                SlotReviewCodePrefixRule(prefix: "ACM"),
                SlotReviewRequiredNameRule(message: "slot review needs this field"),
                SlotReviewRequiredCodeRule(message: "slot review needs this field"),
                SlotReviewCodeLengthRule(maxLength: 86400),
            ]
        )
    }
}
