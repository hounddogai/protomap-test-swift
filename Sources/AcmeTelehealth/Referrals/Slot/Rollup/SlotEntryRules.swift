import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a slot entry must pass. Check returns its problems, or none.
    protocol SlotEntryRule {
        func check(_ item: SlotEntry) -> [String]
    }

    final class SlotEntryRequiredSegmentRule: SlotEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SlotEntry) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SlotEntryCodePrefixRule: SlotEntryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SlotEntry) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SlotEntryAllowedReviewerRule: SlotEntryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SlotEntry) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.reviewer)) {
                return ["reviewer \(item.reviewer) is not allowed"]
            }
            return []
        }
    }

    final class SlotEntryScoreRangeRule: SlotEntryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SlotEntry) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a slot entry.
    final class SlotEntryValidator {
        var rules: [any SlotEntryRule]

        init(rules: [any SlotEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: SlotEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SlotEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SlotEntry]) -> [String: [String]] {
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

    static func defaultSlotEntryValidator() -> SlotEntryValidator {
        return SlotEntryValidator(
            rules: [
                SlotEntryRequiredSegmentRule(message: "slot entry needs this field"),
                SlotEntryCodePrefixRule(prefix: "ACM"),
                SlotEntryAllowedReviewerRule(allowed: []),
                SlotEntryScoreRangeRule(min: 9.2, max: 1359.2),
            ]
        )
    }
}
