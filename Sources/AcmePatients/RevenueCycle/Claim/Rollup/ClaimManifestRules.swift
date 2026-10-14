import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a claim manifest must pass. Check returns its problems, or none.
    protocol ClaimManifestRule {
        func check(_ item: ClaimManifest) -> [String]
    }

    final class ClaimManifestMaximumRangeRule: ClaimManifestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClaimManifest) -> [String] {
            let value = item.maximum
            var problems: [String] = []
            if value < min {
                problems.append("maximum \(value) is below \(min)")
            }
            if value > max {
                problems.append("maximum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ClaimManifestRequiredCodeRule: ClaimManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClaimManifest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClaimManifestRequiredExternalRefRule: ClaimManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClaimManifest) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClaimManifestExternalRefLengthRule: ClaimManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClaimManifest) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ClaimManifestNameLengthRule: ClaimManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClaimManifest) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a claim manifest.
    final class ClaimManifestValidator {
        var rules: [any ClaimManifestRule]

        init(rules: [any ClaimManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: ClaimManifest) -> [String] {
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

        func requireValid(_ item: ClaimManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClaimManifest]) -> [String: [String]] {
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

    static func defaultClaimManifestValidator() -> ClaimManifestValidator {
        return ClaimManifestValidator(
            rules: [
                ClaimManifestMaximumRangeRule(min: 1.9, max: 2004.8),
                ClaimManifestRequiredCodeRule(message: "claim manifest needs an entry"),
                ClaimManifestRequiredExternalRefRule(message: "claim manifest needs this field"),
                ClaimManifestExternalRefLengthRule(maxLength: 1000),
                ClaimManifestNameLengthRule(maxLength: 86400),
            ]
        )
    }
}
