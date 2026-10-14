import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a network threshold must pass. Check returns its problems, or none.
    protocol NetworkThresholdRule {
        func check(_ item: NetworkThreshold) -> [String]
    }

    final class NetworkThresholdRevisionRangeRule: NetworkThresholdRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: NetworkThreshold) -> [String] {
            let value = item.revision
            var problems: [String] = []
            if value < min {
                problems.append("revision \(value) is below \(min)")
            }
            if value > max {
                problems.append("revision \(value) is above \(max)")
            }
            return problems
        }
    }

    final class NetworkThresholdRequiredCodeRule: NetworkThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: NetworkThreshold) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class NetworkThresholdPinnedGuardRule: NetworkThresholdRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: NetworkThreshold) -> [String] {
            if item.pinned && (item.graceDays > limit) {
                return ["grace days \(item.graceDays) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    /// Runs every rule of a network threshold.
    final class NetworkThresholdValidator {
        var rules: [any NetworkThresholdRule]

        init(rules: [any NetworkThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: NetworkThreshold) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: NetworkThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [NetworkThreshold]) -> [String: [String]] {
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

    static func defaultNetworkThresholdValidator() -> NetworkThresholdValidator {
        return NetworkThresholdValidator(
            rules: [
                NetworkThresholdRevisionRangeRule(min: 80, max: 3600),
                NetworkThresholdRequiredCodeRule(message: "network threshold needs this field"),
                NetworkThresholdPinnedGuardRule(limit: 120),
            ]
        )
    }
}
