import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a fallback modality group must pass. Check returns its problems, or none.
    protocol FallbackModalityGroupRule {
        func check(_ item: FallbackModalityGroup) -> [String]
    }

    final class FallbackModalityGroupCodePrefixRule: FallbackModalityGroupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackModalityGroup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FallbackModalityGroupCodeLengthRule: FallbackModalityGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackModalityGroup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackModalityGroupTitleLengthRule: FallbackModalityGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackModalityGroup) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackModalityGroupFloorValueRangeRule: FallbackModalityGroupRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackModalityGroup) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback modality group.
    final class FallbackModalityGroupValidator {
        var rules: [any FallbackModalityGroupRule]

        init(rules: [any FallbackModalityGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackModalityGroup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackModalityGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackModalityGroup]) -> [String: [String]] {
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

    static func defaultFallbackModalityGroupValidator() -> FallbackModalityGroupValidator {
        return FallbackModalityGroupValidator(
            rules: [
                FallbackModalityGroupCodePrefixRule(prefix: "OPS"),
                FallbackModalityGroupCodeLengthRule(maxLength: 16),
                FallbackModalityGroupTitleLengthRule(maxLength: 80),
                FallbackModalityGroupFloorValueRangeRule(min: 3.3, max: 274.8),
            ]
        )
    }
}
