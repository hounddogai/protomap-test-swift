import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a network entry must pass. Check returns its problems, or none.
    protocol NetworkEntryRule {
        func check(_ item: NetworkEntry) -> [String]
    }

    final class NetworkEntryNameLengthRule: NetworkEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: NetworkEntry) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class NetworkEntryRequiredTitleRule: NetworkEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: NetworkEntry) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class NetworkEntryCodeLengthRule: NetworkEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: NetworkEntry) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class NetworkEntryEndsAtRangeRule: NetworkEntryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: NetworkEntry) -> [String] {
            let value = item.endsAt
            if value < min || value > max {
                return ["ends at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a network entry.
    final class NetworkEntryValidator {
        var rules: [any NetworkEntryRule]

        init(rules: [any NetworkEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: NetworkEntry) -> [String] {
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

        func requireValid(_ item: NetworkEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [NetworkEntry]) -> [String: [String]] {
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

    static func defaultNetworkEntryValidator() -> NetworkEntryValidator {
        return NetworkEntryValidator(
            rules: [
                NetworkEntryNameLengthRule(maxLength: 86400),
                NetworkEntryRequiredTitleRule(message: "network entry needs this field"),
                NetworkEntryCodeLengthRule(maxLength: 120),
                NetworkEntryEndsAtRangeRule(min: 32, max: 86400),
            ]
        )
    }
}
