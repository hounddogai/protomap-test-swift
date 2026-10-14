import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a network record must pass. Check returns its problems, or none.
    protocol NetworkRecordRule {
        func check(_ item: NetworkRecord) -> [String]
    }

    final class NetworkRecordNotesLengthRule: NetworkRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: NetworkRecord) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class NetworkRecordAllowedNameRule: NetworkRecordRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: NetworkRecord) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is unknown"]
            }
            return []
        }
    }

    final class NetworkRecordEndsAtRangeRule: NetworkRecordRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: NetworkRecord) -> [String] {
            let value = item.endsAt
            var problems: [String] = []
            if value < min {
                problems.append("ends at \(value) is below \(min)")
            }
            if value > max {
                problems.append("ends at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class NetworkRecordQuantityRangeRule: NetworkRecordRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: NetworkRecord) -> [String] {
            let value = item.quantity
            var problems: [String] = []
            if value < min {
                problems.append("quantity \(value) is below \(min)")
            }
            if value > max {
                problems.append("quantity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class NetworkRecordRequiredCountryRule: NetworkRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: NetworkRecord) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a network record.
    final class NetworkRecordValidator {
        var rules: [any NetworkRecordRule]

        init(rules: [any NetworkRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: NetworkRecord) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: NetworkRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [NetworkRecord]) -> [String: [String]] {
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

    static func defaultNetworkRecordValidator() -> NetworkRecordValidator {
        return NetworkRecordValidator(
            rules: [
                NetworkRecordNotesLengthRule(maxLength: 86400),
                NetworkRecordAllowedNameRule(allowed: ["weighted", "default", "rolling"]),
                NetworkRecordEndsAtRangeRule(min: 32, max: 1000),
                NetworkRecordQuantityRangeRule(min: 32, max: 86400),
                NetworkRecordRequiredCountryRule(message: "network record needs this field"),
            ]
        )
    }
}
