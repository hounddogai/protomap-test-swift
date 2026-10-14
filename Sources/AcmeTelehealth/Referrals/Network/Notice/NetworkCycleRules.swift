import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a network cycle must pass. Check returns its problems, or none.
    protocol NetworkCycleRule {
        func check(_ item: NetworkCycle) -> [String]
    }

    final class NetworkCyclePhoneLengthRule: NetworkCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: NetworkCycle) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class NetworkCycleRequiredCodeRule: NetworkCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: NetworkCycle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class NetworkCycleNotesLengthRule: NetworkCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: NetworkCycle) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class NetworkCycleRequiredTitleRule: NetworkCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: NetworkCycle) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class NetworkCycleVersionRangeRule: NetworkCycleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: NetworkCycle) -> [String] {
            let value = item.version
            var problems: [String] = []
            if value < min {
                problems.append("version \(value) is below \(min)")
            }
            if value > max {
                problems.append("version \(value) is above \(max)")
            }
            return problems
        }
    }

    final class NetworkCycleCodePrefixRule: NetworkCycleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: NetworkCycle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a network cycle.
    final class NetworkCycleValidator {
        var rules: [any NetworkCycleRule]

        init(rules: [any NetworkCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: NetworkCycle) -> [String] {
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

        func requireValid(_ item: NetworkCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [NetworkCycle]) -> [String: [String]] {
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

    static func defaultNetworkCycleValidator() -> NetworkCycleValidator {
        return NetworkCycleValidator(
            rules: [
                NetworkCyclePhoneLengthRule(maxLength: 64),
                NetworkCycleRequiredCodeRule(message: "network cycle needs an entry"),
                NetworkCycleNotesLengthRule(maxLength: 32),
                NetworkCycleRequiredTitleRule(message: "network cycle needs a value"),
                NetworkCycleVersionRangeRule(min: 255, max: 86400),
                NetworkCycleCodePrefixRule(prefix: "REF"),
            ]
        )
    }
}
