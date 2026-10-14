import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a weighted recall bundle must pass. Check returns its problems, or none.
    protocol WeightedRecallBundleRule {
        func check(_ item: WeightedRecallBundle) -> [String]
    }

    final class WeightedRecallBundleRequiredCodeRule: WeightedRecallBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedRecallBundle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedRecallBundleActiveGuardRule: WeightedRecallBundleRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: WeightedRecallBundle) -> [String] {
            if item.active && (item.createdAt > limit) {
                return ["created at \(item.createdAt) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class WeightedRecallBundleRequiredClinicianIDRule: WeightedRecallBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedRecallBundle) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedRecallBundleNameLengthRule: WeightedRecallBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedRecallBundle) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted recall bundle.
    final class WeightedRecallBundleValidator {
        var rules: [any WeightedRecallBundleRule]

        init(rules: [any WeightedRecallBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedRecallBundle) -> [String] {
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

        func requireValid(_ item: WeightedRecallBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedRecallBundle]) -> [String: [String]] {
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

    static func defaultWeightedRecallBundleValidator() -> WeightedRecallBundleValidator {
        return WeightedRecallBundleValidator(
            rules: [
                WeightedRecallBundleRequiredCodeRule(message: "weighted recall bundle needs a value"),
                WeightedRecallBundleActiveGuardRule(limit: 32),
                WeightedRecallBundleRequiredClinicianIDRule(message: "weighted recall bundle needs an entry"),
                WeightedRecallBundleNameLengthRule(maxLength: 16),
            ]
        )
    }
}
