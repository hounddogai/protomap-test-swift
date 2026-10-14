import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a shift bundle must pass. Check returns its problems, or none.
    protocol ShiftBundleRule {
        func check(_ item: ShiftBundle) -> [String]
    }

    final class ShiftBundleRegionLengthRule: ShiftBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ShiftBundle) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ShiftBundleCreatedAtRangeRule: ShiftBundleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ShiftBundle) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ShiftBundleCodePrefixRule: ShiftBundleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ShiftBundle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ShiftBundleCopayRangeRule: ShiftBundleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ShiftBundle) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a shift bundle.
    final class ShiftBundleValidator {
        var rules: [any ShiftBundleRule]

        init(rules: [any ShiftBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: ShiftBundle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ShiftBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ShiftBundle]) -> [String: [String]] {
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

    static func defaultShiftBundleValidator() -> ShiftBundleValidator {
        return ShiftBundleValidator(
            rules: [
                ShiftBundleRegionLengthRule(maxLength: 64),
                ShiftBundleCreatedAtRangeRule(min: 120, max: 1000),
                ShiftBundleCodePrefixRule(prefix: "OPS"),
                ShiftBundleCopayRangeRule(min: 2.5, max: 1258.2),
            ]
        )
    }
}
