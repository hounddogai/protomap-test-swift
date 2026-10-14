import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a network assignment must pass. Check returns its problems, or none.
    protocol NetworkAssignmentRule {
        func check(_ item: NetworkAssignment) -> [String]
    }

    final class NetworkAssignmentFloorValueRangeRule: NetworkAssignmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: NetworkAssignment) -> [String] {
            let value = item.floorValue
            var problems: [String] = []
            if value < min {
                problems.append("floor value \(value) is below \(min)")
            }
            if value > max {
                problems.append("floor value \(value) is above \(max)")
            }
            return problems
        }
    }

    final class NetworkAssignmentCodeLengthRule: NetworkAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: NetworkAssignment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class NetworkAssignmentRequiredSourceRule: NetworkAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: NetworkAssignment) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class NetworkAssignmentRequiredLabelRule: NetworkAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: NetworkAssignment) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class NetworkAssignmentTimezoneLengthRule: NetworkAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: NetworkAssignment) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a network assignment.
    final class NetworkAssignmentValidator {
        var rules: [any NetworkAssignmentRule]

        init(rules: [any NetworkAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: NetworkAssignment) -> [String] {
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

        func requireValid(_ item: NetworkAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [NetworkAssignment]) -> [String: [String]] {
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

    static func defaultNetworkAssignmentValidator() -> NetworkAssignmentValidator {
        return NetworkAssignmentValidator(
            rules: [
                NetworkAssignmentFloorValueRangeRule(min: 9.7, max: 4439.2),
                NetworkAssignmentCodeLengthRule(maxLength: 86400),
                NetworkAssignmentRequiredSourceRule(message: "network assignment needs an entry"),
                NetworkAssignmentRequiredLabelRule(message: "network assignment needs a value"),
                NetworkAssignmentTimezoneLengthRule(maxLength: 1000),
            ]
        )
    }
}
