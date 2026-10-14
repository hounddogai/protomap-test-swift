import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a weighted study bundle must pass. Check returns its problems, or none.
    protocol WeightedStudyBundleRule {
        func check(_ item: WeightedStudyBundle) -> [String]
    }

    final class WeightedStudyBundleBedLengthRule: WeightedStudyBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedStudyBundle) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedStudyBundleCapacityRangeRule: WeightedStudyBundleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedStudyBundle) -> [String] {
            let value = item.capacity
            if value < min || value > max {
                return ["capacity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WeightedStudyBundleRequiredCodeRule: WeightedStudyBundleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedStudyBundle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedStudyBundleDosageMgRangeRule: WeightedStudyBundleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedStudyBundle) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WeightedStudyBundleAllowedBedRule: WeightedStudyBundleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WeightedStudyBundle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.bed)) {
                return ["bed \(item.bed) is too long"]
            }
            return []
        }
    }

    final class WeightedStudyBundleCodePrefixRule: WeightedStudyBundleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WeightedStudyBundle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted study bundle.
    final class WeightedStudyBundleValidator {
        var rules: [any WeightedStudyBundleRule]

        init(rules: [any WeightedStudyBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedStudyBundle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedStudyBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedStudyBundle]) -> [String: [String]] {
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

    static func defaultWeightedStudyBundleValidator() -> WeightedStudyBundleValidator {
        return WeightedStudyBundleValidator(
            rules: [
                WeightedStudyBundleBedLengthRule(maxLength: 1000),
                WeightedStudyBundleCapacityRangeRule(min: 32, max: 32),
                WeightedStudyBundleRequiredCodeRule(message: "weighted study bundle needs this field"),
                WeightedStudyBundleDosageMgRangeRule(min: 5.4, max: 1152.8),
                WeightedStudyBundleAllowedBedRule(allowed: ["regional", "adaptive", "adaptive"]),
                WeightedStudyBundleCodePrefixRule(prefix: "REF"),
            ]
        )
    }
}
