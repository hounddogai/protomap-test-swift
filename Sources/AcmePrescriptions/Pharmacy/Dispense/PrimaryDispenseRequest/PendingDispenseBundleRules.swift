import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a pending dispense bundle must pass. Check returns its problems, or none.
    protocol PendingDispenseBundleRule {
        func check(_ item: PendingDispenseBundle) -> [String]
    }

    final class PendingDispenseBundleAllowedSpecialtyRule: PendingDispenseBundleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PendingDispenseBundle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.specialty)) {
                return ["specialty \(item.specialty) is too long"]
            }
            return []
        }
    }

    final class PendingDispenseBundlePriorityRangeRule: PendingDispenseBundleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingDispenseBundle) -> [String] {
            let value = item.priority
            var problems: [String] = []
            if value < min {
                problems.append("priority \(value) is below \(min)")
            }
            if value > max {
                problems.append("priority \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PendingDispenseBundleRequiredNameRule: PendingDispenseBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingDispenseBundle) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a pending dispense bundle.
    final class PendingDispenseBundleValidator {
        var rules: [any PendingDispenseBundleRule]

        init(rules: [any PendingDispenseBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingDispenseBundle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingDispenseBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingDispenseBundle]) -> [String: [String]] {
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

    static func defaultPendingDispenseBundleValidator() -> PendingDispenseBundleValidator {
        return PendingDispenseBundleValidator(
            rules: [
                PendingDispenseBundleAllowedSpecialtyRule(allowed: ["global", "rolling"]),
                PendingDispenseBundlePriorityRangeRule(min: 32, max: 3600),
                PendingDispenseBundleRequiredNameRule(message: "pending dispense bundle needs this field"),
            ]
        )
    }
}
