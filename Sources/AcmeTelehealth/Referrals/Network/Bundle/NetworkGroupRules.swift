import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a network group must pass. Check returns its problems, or none.
    protocol NetworkGroupRule {
        func check(_ item: NetworkGroup) -> [String]
    }

    final class NetworkGroupAllowedCodeRule: NetworkGroupRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: NetworkGroup) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is stale"]
            }
            return []
        }
    }

    final class NetworkGroupTitleLengthRule: NetworkGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: NetworkGroup) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class NetworkGroupPhoneLengthRule: NetworkGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: NetworkGroup) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class NetworkGroupGraceDaysRangeRule: NetworkGroupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: NetworkGroup) -> [String] {
            let value = item.graceDays
            var problems: [String] = []
            if value < min {
                problems.append("grace days \(value) is below \(min)")
            }
            if value > max {
                problems.append("grace days \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a network group.
    final class NetworkGroupValidator {
        var rules: [any NetworkGroupRule]

        init(rules: [any NetworkGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: NetworkGroup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: NetworkGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [NetworkGroup]) -> [String: [String]] {
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

    static func defaultNetworkGroupValidator() -> NetworkGroupValidator {
        return NetworkGroupValidator(
            rules: [
                NetworkGroupAllowedCodeRule(allowed: []),
                NetworkGroupTitleLengthRule(maxLength: 64),
                NetworkGroupPhoneLengthRule(maxLength: 255),
                NetworkGroupGraceDaysRangeRule(min: 16, max: 80),
            ]
        )
    }
}
