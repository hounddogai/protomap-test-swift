import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a default bed board rollup must pass. Check returns its problems, or none.
    protocol DefaultBedBoardRollupRule {
        func check(_ item: DefaultBedBoardRollup) -> [String]
    }

    final class DefaultBedBoardRollupCodePrefixRule: DefaultBedBoardRollupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DefaultBedBoardRollup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DefaultBedBoardRollupLabelLengthRule: DefaultBedBoardRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultBedBoardRollup) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultBedBoardRollupRequiredCodeRule: DefaultBedBoardRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultBedBoardRollup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultBedBoardRollupPhoneLengthRule: DefaultBedBoardRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultBedBoardRollup) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultBedBoardRollupRequiredSegmentRule: DefaultBedBoardRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultBedBoardRollup) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a default bed board rollup.
    final class DefaultBedBoardRollupValidator {
        var rules: [any DefaultBedBoardRollupRule]

        init(rules: [any DefaultBedBoardRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultBedBoardRollup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultBedBoardRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultBedBoardRollup]) -> [String: [String]] {
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

    static func defaultDefaultBedBoardRollupValidator() -> DefaultBedBoardRollupValidator {
        return DefaultBedBoardRollupValidator(
            rules: [
                DefaultBedBoardRollupCodePrefixRule(prefix: "X"),
                DefaultBedBoardRollupLabelLengthRule(maxLength: 1000),
                DefaultBedBoardRollupRequiredCodeRule(message: "default bed board rollup needs this field"),
                DefaultBedBoardRollupPhoneLengthRule(maxLength: 255),
                DefaultBedBoardRollupRequiredSegmentRule(message: "default bed board rollup needs an entry"),
            ]
        )
    }
}
