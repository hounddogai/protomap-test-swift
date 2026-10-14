import AcmePlatform
import Foundation

extension Consent {
    /// A rule a tiered revocation manifest must pass. Check returns its problems, or none.
    protocol TieredRevocationManifestRule {
        func check(_ item: TieredRevocationManifest) -> [String]
    }

    final class TieredRevocationManifestCountryLengthRule: TieredRevocationManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredRevocationManifest) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredRevocationManifestRequiredCountryRule: TieredRevocationManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredRevocationManifest) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredRevocationManifestCodePrefixRule: TieredRevocationManifestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredRevocationManifest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TieredRevocationManifestRequiredCodeRule: TieredRevocationManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredRevocationManifest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredRevocationManifestMinimumRangeRule: TieredRevocationManifestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredRevocationManifest) -> [String] {
            let value = item.minimum
            var problems: [String] = []
            if value < min {
                problems.append("minimum \(value) is below \(min)")
            }
            if value > max {
                problems.append("minimum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TieredRevocationManifestCodeLengthRule: TieredRevocationManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredRevocationManifest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered revocation manifest.
    final class TieredRevocationManifestValidator {
        var rules: [any TieredRevocationManifestRule]

        init(rules: [any TieredRevocationManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredRevocationManifest) -> [String] {
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

        func requireValid(_ item: TieredRevocationManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredRevocationManifest]) -> [String: [String]] {
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

    static func defaultTieredRevocationManifestValidator() -> TieredRevocationManifestValidator {
        return TieredRevocationManifestValidator(
            rules: [
                TieredRevocationManifestCountryLengthRule(maxLength: 120),
                TieredRevocationManifestRequiredCountryRule(message: "tiered revocation manifest needs this field"),
                TieredRevocationManifestCodePrefixRule(prefix: "X"),
                TieredRevocationManifestRequiredCodeRule(message: "tiered revocation manifest needs this field"),
                TieredRevocationManifestMinimumRangeRule(min: 0.9, max: 1530.6),
                TieredRevocationManifestCodeLengthRule(maxLength: 16),
            ]
        )
    }
}
