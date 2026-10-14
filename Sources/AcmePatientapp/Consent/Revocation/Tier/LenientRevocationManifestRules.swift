import AcmePlatform
import Foundation

extension Consent {
    /// A rule a lenient revocation manifest must pass. Check returns its problems, or none.
    protocol LenientRevocationManifestRule {
        func check(_ item: LenientRevocationManifest) -> [String]
    }

    final class LenientRevocationManifestCodeLengthRule: LenientRevocationManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientRevocationManifest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientRevocationManifestRegionLengthRule: LenientRevocationManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientRevocationManifest) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientRevocationManifestWindowDaysRangeRule: LenientRevocationManifestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientRevocationManifest) -> [String] {
            let value = item.windowDays
            var problems: [String] = []
            if value < min {
                problems.append("window days \(value) is below \(min)")
            }
            if value > max {
                problems.append("window days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LenientRevocationManifestFloorValueRangeRule: LenientRevocationManifestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientRevocationManifest) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient revocation manifest.
    final class LenientRevocationManifestValidator {
        var rules: [any LenientRevocationManifestRule]

        init(rules: [any LenientRevocationManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientRevocationManifest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientRevocationManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientRevocationManifest]) -> [String: [String]] {
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

    static func defaultLenientRevocationManifestValidator() -> LenientRevocationManifestValidator {
        return LenientRevocationManifestValidator(
            rules: [
                LenientRevocationManifestCodeLengthRule(maxLength: 80),
                LenientRevocationManifestRegionLengthRule(maxLength: 3600),
                LenientRevocationManifestWindowDaysRangeRule(min: 3600, max: 86400),
                LenientRevocationManifestFloorValueRangeRule(min: 4.9, max: 1937.1),
            ]
        )
    }
}
