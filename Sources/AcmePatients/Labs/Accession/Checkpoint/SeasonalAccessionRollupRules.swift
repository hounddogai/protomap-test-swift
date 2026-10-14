import AcmePlatform
import Foundation

extension Labs {
    /// A rule a seasonal accession rollup must pass. Check returns its problems, or none.
    protocol SeasonalAccessionRollupRule {
        func check(_ item: SeasonalAccessionRollup) -> [String]
    }

    final class SeasonalAccessionRollupUpdatedAtRangeRule: SeasonalAccessionRollupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalAccessionRollup) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SeasonalAccessionRollupAllowedPatientRefRule: SeasonalAccessionRollupRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SeasonalAccessionRollup) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.patientRef)) {
                return ["patient ref \(item.patientRef) is out of range"]
            }
            return []
        }
    }

    final class SeasonalAccessionRollupRequiredLabelRule: SeasonalAccessionRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalAccessionRollup) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalAccessionRollupCodePrefixRule: SeasonalAccessionRollupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SeasonalAccessionRollup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SeasonalAccessionRollupSegmentLengthRule: SeasonalAccessionRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalAccessionRollup) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalAccessionRollupRequiredCodeRule: SeasonalAccessionRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalAccessionRollup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal accession rollup.
    final class SeasonalAccessionRollupValidator {
        var rules: [any SeasonalAccessionRollupRule]

        init(rules: [any SeasonalAccessionRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalAccessionRollup) -> [String] {
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

        func requireValid(_ item: SeasonalAccessionRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalAccessionRollup]) -> [String: [String]] {
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

    static func defaultSeasonalAccessionRollupValidator() -> SeasonalAccessionRollupValidator {
        return SeasonalAccessionRollupValidator(
            rules: [
                SeasonalAccessionRollupUpdatedAtRangeRule(min: 120, max: 255),
                SeasonalAccessionRollupAllowedPatientRefRule(allowed: ["fallback", "weighted"]),
                SeasonalAccessionRollupRequiredLabelRule(message: "seasonal accession rollup needs this field"),
                SeasonalAccessionRollupCodePrefixRule(prefix: "OPS"),
                SeasonalAccessionRollupSegmentLengthRule(maxLength: 32),
                SeasonalAccessionRollupRequiredCodeRule(message: "seasonal accession rollup needs a value"),
            ]
        )
    }
}
