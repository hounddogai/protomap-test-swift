import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a strict float pool manifest must pass. Check returns its problems, or none.
    protocol StrictFloatPoolManifestRule {
        func check(_ item: StrictFloatPoolManifest) -> [String]
    }

    final class StrictFloatPoolManifestRequiredCodeRule: StrictFloatPoolManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictFloatPoolManifest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictFloatPoolManifestFloorValueRangeRule: StrictFloatPoolManifestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictFloatPoolManifest) -> [String] {
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

    final class StrictFloatPoolManifestCodeLengthRule: StrictFloatPoolManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictFloatPoolManifest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict float pool manifest.
    final class StrictFloatPoolManifestValidator {
        var rules: [any StrictFloatPoolManifestRule]

        init(rules: [any StrictFloatPoolManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictFloatPoolManifest) -> [String] {
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

        func requireValid(_ item: StrictFloatPoolManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictFloatPoolManifest]) -> [String: [String]] {
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

    static func defaultStrictFloatPoolManifestValidator() -> StrictFloatPoolManifestValidator {
        return StrictFloatPoolManifestValidator(
            rules: [
                StrictFloatPoolManifestRequiredCodeRule(message: "strict float pool manifest needs an entry"),
                StrictFloatPoolManifestFloorValueRangeRule(min: 4.3, max: 3834.5),
                StrictFloatPoolManifestCodeLengthRule(maxLength: 86400),
            ]
        )
    }
}
