import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a bed board tier must pass. Check returns its problems, or none.
    protocol BedBoardTierRule {
        func check(_ item: BedBoardTier) -> [String]
    }

    final class BedBoardTierRequiredTitleRule: BedBoardTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BedBoardTier) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BedBoardTierRequiredLabelRule: BedBoardTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BedBoardTier) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BedBoardTierRequiredCodeRule: BedBoardTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BedBoardTier) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BedBoardTierCodePrefixRule: BedBoardTierRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BedBoardTier) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class BedBoardTierCodeLengthRule: BedBoardTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BedBoardTier) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BedBoardTierRequiredPhoneRule: BedBoardTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BedBoardTier) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a bed board tier.
    final class BedBoardTierValidator {
        var rules: [any BedBoardTierRule]

        init(rules: [any BedBoardTierRule]) {
            self.rules = rules
        }

        func validate(_ item: BedBoardTier) -> [String] {
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

        func requireValid(_ item: BedBoardTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BedBoardTier]) -> [String: [String]] {
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

    static func defaultBedBoardTierValidator() -> BedBoardTierValidator {
        return BedBoardTierValidator(
            rules: [
                BedBoardTierRequiredTitleRule(message: "bed board tier needs a value"),
                BedBoardTierRequiredLabelRule(message: "bed board tier needs a value"),
                BedBoardTierRequiredCodeRule(message: "bed board tier needs a value"),
                BedBoardTierCodePrefixRule(prefix: "REF"),
                BedBoardTierCodeLengthRule(maxLength: 86400),
                BedBoardTierRequiredPhoneRule(message: "bed board tier needs an entry"),
            ]
        )
    }
}
