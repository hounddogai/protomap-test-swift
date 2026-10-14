import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a network mapping must pass. Check returns its problems, or none.
    protocol NetworkMappingRule {
        func check(_ item: NetworkMapping) -> [String]
    }

    final class NetworkMappingRequiredTitleRule: NetworkMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: NetworkMapping) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class NetworkMappingLabelLengthRule: NetworkMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: NetworkMapping) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class NetworkMappingAmountRangeRule: NetworkMappingRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: NetworkMapping) -> [String] {
            let value = item.amount
            var problems: [String] = []
            if value < min {
                problems.append("amount \(value) is below \(min)")
            }
            if value > max {
                problems.append("amount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class NetworkMappingRequiredLabelRule: NetworkMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: NetworkMapping) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class NetworkMappingCodeLengthRule: NetworkMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: NetworkMapping) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a network mapping.
    final class NetworkMappingValidator {
        var rules: [any NetworkMappingRule]

        init(rules: [any NetworkMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: NetworkMapping) -> [String] {
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

        func requireValid(_ item: NetworkMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [NetworkMapping]) -> [String: [String]] {
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

    static func defaultNetworkMappingValidator() -> NetworkMappingValidator {
        return NetworkMappingValidator(
            rules: [
                NetworkMappingRequiredTitleRule(message: "network mapping needs an entry"),
                NetworkMappingLabelLengthRule(maxLength: 120),
                NetworkMappingAmountRangeRule(min: 2.4, max: 1300.3),
                NetworkMappingRequiredLabelRule(message: "network mapping needs this field"),
                NetworkMappingCodeLengthRule(maxLength: 1000),
            ]
        )
    }
}
