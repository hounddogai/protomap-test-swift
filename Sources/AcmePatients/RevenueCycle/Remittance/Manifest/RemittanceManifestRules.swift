import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a remittance manifest must pass. Check returns its problems, or none.
    protocol RemittanceManifestRule {
        func check(_ item: RemittanceManifest) -> [String]
    }

    final class RemittanceManifestRequiredCodeRule: RemittanceManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RemittanceManifest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RemittanceManifestUpdatedAtRangeRule: RemittanceManifestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RemittanceManifest) -> [String] {
            let value = item.updatedAt
            var problems: [String] = []
            if value < min {
                problems.append("updated at \(value) is below \(min)")
            }
            if value > max {
                problems.append("updated at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RemittanceManifestLabelLengthRule: RemittanceManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RemittanceManifest) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RemittanceManifestCapacityRangeRule: RemittanceManifestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RemittanceManifest) -> [String] {
            let value = item.capacity
            if value < min || value > max {
                return ["capacity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a remittance manifest.
    final class RemittanceManifestValidator {
        var rules: [any RemittanceManifestRule]

        init(rules: [any RemittanceManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: RemittanceManifest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RemittanceManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RemittanceManifest]) -> [String: [String]] {
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

    static func defaultRemittanceManifestValidator() -> RemittanceManifestValidator {
        return RemittanceManifestValidator(
            rules: [
                RemittanceManifestRequiredCodeRule(message: "remittance manifest needs an entry"),
                RemittanceManifestUpdatedAtRangeRule(min: 80, max: 255),
                RemittanceManifestLabelLengthRule(maxLength: 16),
                RemittanceManifestCapacityRangeRule(min: 120, max: 86400),
            ]
        )
    }
}
