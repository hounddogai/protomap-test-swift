import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a weighted handoff manifest must pass. Check returns its problems, or none.
    protocol WeightedHandoffManifestRule {
        func check(_ item: WeightedHandoffManifest) -> [String]
    }

    final class WeightedHandoffManifestAllowedTitleRule: WeightedHandoffManifestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WeightedHandoffManifest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is not allowed"]
            }
            return []
        }
    }

    final class WeightedHandoffManifestBedLengthRule: WeightedHandoffManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedHandoffManifest) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedHandoffManifestCodePrefixRule: WeightedHandoffManifestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WeightedHandoffManifest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted handoff manifest.
    final class WeightedHandoffManifestValidator {
        var rules: [any WeightedHandoffManifestRule]

        init(rules: [any WeightedHandoffManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedHandoffManifest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedHandoffManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedHandoffManifest]) -> [String: [String]] {
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

    static func defaultWeightedHandoffManifestValidator() -> WeightedHandoffManifestValidator {
        return WeightedHandoffManifestValidator(
            rules: [
                WeightedHandoffManifestAllowedTitleRule(allowed: ["global", "scheduled"]),
                WeightedHandoffManifestBedLengthRule(maxLength: 32),
                WeightedHandoffManifestCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
