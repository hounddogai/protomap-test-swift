import AcmePlatform
import Foundation

extension Labs {
    /// A rule a panel bundle must pass. Check returns its problems, or none.
    protocol PanelBundleRule {
        func check(_ item: PanelBundle) -> [String]
    }

    final class PanelBundleEndsAtRangeRule: PanelBundleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PanelBundle) -> [String] {
            let value = item.endsAt
            var problems: [String] = []
            if value < min {
                problems.append("ends at \(value) is below \(min)")
            }
            if value > max {
                problems.append("ends at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PanelBundleCodePrefixRule: PanelBundleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PanelBundle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PanelBundleRegionLengthRule: PanelBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PanelBundle) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PanelBundleBudgetRangeRule: PanelBundleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PanelBundle) -> [String] {
            let value = item.budget
            var problems: [String] = []
            if value < min {
                problems.append("budget \(value) is below \(min)")
            }
            if value > max {
                problems.append("budget \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a panel bundle.
    final class PanelBundleValidator {
        var rules: [any PanelBundleRule]

        init(rules: [any PanelBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: PanelBundle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PanelBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PanelBundle]) -> [String: [String]] {
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

    static func defaultPanelBundleValidator() -> PanelBundleValidator {
        return PanelBundleValidator(
            rules: [
                PanelBundleEndsAtRangeRule(min: 120, max: 255),
                PanelBundleCodePrefixRule(prefix: "OPS"),
                PanelBundleRegionLengthRule(maxLength: 16),
                PanelBundleBudgetRangeRule(min: 7.6, max: 4205.9),
            ]
        )
    }
}
