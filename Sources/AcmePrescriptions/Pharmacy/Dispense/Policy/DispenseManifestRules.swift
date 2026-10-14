import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a dispense manifest must pass. Check returns its problems, or none.
    protocol DispenseManifestRule {
        func check(_ item: DispenseManifest) -> [String]
    }

    final class DispenseManifestVersionRangeRule: DispenseManifestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DispenseManifest) -> [String] {
            let value = item.version
            if value < min || value > max {
                return ["version \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DispenseManifestRegionLengthRule: DispenseManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DispenseManifest) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DispenseManifestCodeLengthRule: DispenseManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DispenseManifest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DispenseManifestThresholdRangeRule: DispenseManifestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DispenseManifest) -> [String] {
            let value = item.threshold
            var problems: [String] = []
            if value < min {
                problems.append("threshold \(value) is below \(min)")
            }
            if value > max {
                problems.append("threshold \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a dispense manifest.
    final class DispenseManifestValidator {
        var rules: [any DispenseManifestRule]

        init(rules: [any DispenseManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: DispenseManifest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DispenseManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DispenseManifest]) -> [String: [String]] {
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

    static func defaultDispenseManifestValidator() -> DispenseManifestValidator {
        return DispenseManifestValidator(
            rules: [
                DispenseManifestVersionRangeRule(min: 16, max: 255),
                DispenseManifestRegionLengthRule(maxLength: 3600),
                DispenseManifestCodeLengthRule(maxLength: 86400),
                DispenseManifestThresholdRangeRule(min: 4.3, max: 4518.0),
            ]
        )
    }
}
