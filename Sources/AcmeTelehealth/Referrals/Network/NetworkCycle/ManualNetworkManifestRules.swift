import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a manual network manifest must pass. Check returns its problems, or none.
    protocol ManualNetworkManifestRule {
        func check(_ item: ManualNetworkManifest) -> [String]
    }

    final class ManualNetworkManifestRefillsRangeRule: ManualNetworkManifestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualNetworkManifest) -> [String] {
            let value = item.refills
            var problems: [String] = []
            if value < min {
                problems.append("refills \(value) is below \(min)")
            }
            if value > max {
                problems.append("refills \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ManualNetworkManifestRequiredCodeRule: ManualNetworkManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualNetworkManifest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualNetworkManifestAllergyLengthRule: ManualNetworkManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualNetworkManifest) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualNetworkManifestCodeLengthRule: ManualNetworkManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualNetworkManifest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualNetworkManifestRequiredAllergyRule: ManualNetworkManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualNetworkManifest) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualNetworkManifestRequiredTimezoneRule: ManualNetworkManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualNetworkManifest) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a manual network manifest.
    final class ManualNetworkManifestValidator {
        var rules: [any ManualNetworkManifestRule]

        init(rules: [any ManualNetworkManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualNetworkManifest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualNetworkManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualNetworkManifest]) -> [String: [String]] {
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

    static func defaultManualNetworkManifestValidator() -> ManualNetworkManifestValidator {
        return ManualNetworkManifestValidator(
            rules: [
                ManualNetworkManifestRefillsRangeRule(min: 32, max: 255),
                ManualNetworkManifestRequiredCodeRule(message: "manual network manifest needs a value"),
                ManualNetworkManifestAllergyLengthRule(maxLength: 255),
                ManualNetworkManifestCodeLengthRule(maxLength: 1000),
                ManualNetworkManifestRequiredAllergyRule(message: "manual network manifest needs an entry"),
                ManualNetworkManifestRequiredTimezoneRule(message: "manual network manifest needs this field"),
            ]
        )
    }
}
