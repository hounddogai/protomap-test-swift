import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a regional rounding checkpoint must pass. Check returns its problems, or none.
    protocol RegionalRoundingCheckpointRule {
        func check(_ item: RegionalRoundingCheckpoint) -> [String]
    }

    final class RegionalRoundingCheckpointRequiredLabelRule: RegionalRoundingCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalRoundingCheckpoint) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalRoundingCheckpointApprovedGuardRule: RegionalRoundingCheckpointRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: RegionalRoundingCheckpoint) -> [String] {
            if item.approved && (item.ratio > limit) {
                return ["ratio \(item.ratio) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class RegionalRoundingCheckpointCodePrefixRule: RegionalRoundingCheckpointRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RegionalRoundingCheckpoint) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RegionalRoundingCheckpointRequiredRegionRule: RegionalRoundingCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalRoundingCheckpoint) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalRoundingCheckpointLabelLengthRule: RegionalRoundingCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalRoundingCheckpoint) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional rounding checkpoint.
    final class RegionalRoundingCheckpointValidator {
        var rules: [any RegionalRoundingCheckpointRule]

        init(rules: [any RegionalRoundingCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalRoundingCheckpoint) -> [String] {
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

        func requireValid(_ item: RegionalRoundingCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalRoundingCheckpoint]) -> [String: [String]] {
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

    static func defaultRegionalRoundingCheckpointValidator() -> RegionalRoundingCheckpointValidator {
        return RegionalRoundingCheckpointValidator(
            rules: [
                RegionalRoundingCheckpointRequiredLabelRule(message: "regional rounding checkpoint needs a value"),
                RegionalRoundingCheckpointApprovedGuardRule(limit: 4.6),
                RegionalRoundingCheckpointCodePrefixRule(prefix: "ACM"),
                RegionalRoundingCheckpointRequiredRegionRule(message: "regional rounding checkpoint needs an entry"),
                RegionalRoundingCheckpointLabelLengthRule(maxLength: 32),
            ]
        )
    }
}
