import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a fallback dispense manifest must pass. Check returns its problems, or none.
    protocol FallbackDispenseManifestRule {
        func check(_ item: FallbackDispenseManifest) -> [String]
    }

    final class FallbackDispenseManifestRatioRangeRule: FallbackDispenseManifestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackDispenseManifest) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FallbackDispenseManifestRequiredTitleRule: FallbackDispenseManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackDispenseManifest) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackDispenseManifestCodeLengthRule: FallbackDispenseManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackDispenseManifest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackDispenseManifestStartsAtRangeRule: FallbackDispenseManifestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackDispenseManifest) -> [String] {
            let value = item.startsAt
            var problems: [String] = []
            if value < min {
                problems.append("starts at \(value) is below \(min)")
            }
            if value > max {
                problems.append("starts at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FallbackDispenseManifestAllowedTitleRule: FallbackDispenseManifestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FallbackDispenseManifest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is out of range"]
            }
            return []
        }
    }

    final class FallbackDispenseManifestTitleLengthRule: FallbackDispenseManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackDispenseManifest) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback dispense manifest.
    final class FallbackDispenseManifestValidator {
        var rules: [any FallbackDispenseManifestRule]

        init(rules: [any FallbackDispenseManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackDispenseManifest) -> [String] {
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

        func requireValid(_ item: FallbackDispenseManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackDispenseManifest]) -> [String: [String]] {
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

    static func defaultFallbackDispenseManifestValidator() -> FallbackDispenseManifestValidator {
        return FallbackDispenseManifestValidator(
            rules: [
                FallbackDispenseManifestRatioRangeRule(min: 3.0, max: 2638.3),
                FallbackDispenseManifestRequiredTitleRule(message: "fallback dispense manifest needs this field"),
                FallbackDispenseManifestCodeLengthRule(maxLength: 1000),
                FallbackDispenseManifestStartsAtRangeRule(min: 1000, max: 3600),
                FallbackDispenseManifestAllowedTitleRule(allowed: ["manual", "strict"]),
                FallbackDispenseManifestTitleLengthRule(maxLength: 16),
            ]
        )
    }
}
