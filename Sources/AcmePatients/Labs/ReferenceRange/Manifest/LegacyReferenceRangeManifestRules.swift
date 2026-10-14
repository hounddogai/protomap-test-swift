import AcmePlatform
import Foundation

extension Labs {
    /// A rule a legacy reference range manifest must pass. Check returns its problems, or none.
    protocol LegacyReferenceRangeManifestRule {
        func check(_ item: LegacyReferenceRangeManifest) -> [String]
    }

    final class LegacyReferenceRangeManifestNameLengthRule: LegacyReferenceRangeManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyReferenceRangeManifest) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyReferenceRangeManifestFloorValueRangeRule: LegacyReferenceRangeManifestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyReferenceRangeManifest) -> [String] {
            let value = item.floorValue
            var problems: [String] = []
            if value < min {
                problems.append("floor value \(value) is below \(min)")
            }
            if value > max {
                problems.append("floor value \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LegacyReferenceRangeManifestRevisionRangeRule: LegacyReferenceRangeManifestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyReferenceRangeManifest) -> [String] {
            let value = item.revision
            var problems: [String] = []
            if value < min {
                problems.append("revision \(value) is below \(min)")
            }
            if value > max {
                problems.append("revision \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LegacyReferenceRangeManifestRateRangeRule: LegacyReferenceRangeManifestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyReferenceRangeManifest) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy reference range manifest.
    final class LegacyReferenceRangeManifestValidator {
        var rules: [any LegacyReferenceRangeManifestRule]

        init(rules: [any LegacyReferenceRangeManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyReferenceRangeManifest) -> [String] {
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

        func requireValid(_ item: LegacyReferenceRangeManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyReferenceRangeManifest]) -> [String: [String]] {
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

    static func defaultLegacyReferenceRangeManifestValidator() -> LegacyReferenceRangeManifestValidator {
        return LegacyReferenceRangeManifestValidator(
            rules: [
                LegacyReferenceRangeManifestNameLengthRule(maxLength: 32),
                LegacyReferenceRangeManifestFloorValueRangeRule(min: 4.0, max: 1789.1),
                LegacyReferenceRangeManifestRevisionRangeRule(min: 64, max: 3600),
                LegacyReferenceRangeManifestRateRangeRule(min: 8.5, max: 4819.0),
            ]
        )
    }
}
