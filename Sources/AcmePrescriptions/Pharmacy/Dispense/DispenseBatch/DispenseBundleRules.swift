import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a dispense bundle must pass. Check returns its problems, or none.
    protocol DispenseBundleRule {
        func check(_ item: DispenseBundle) -> [String]
    }

    final class DispenseBundleContactEmailLengthRule: DispenseBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DispenseBundle) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DispenseBundlePriorityRangeRule: DispenseBundleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DispenseBundle) -> [String] {
            let value = item.priority
            var problems: [String] = []
            if value < min {
                problems.append("priority \(value) is below \(min)")
            }
            if value > max {
                problems.append("priority \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DispenseBundleFloorValueRangeRule: DispenseBundleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DispenseBundle) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DispenseBundleTitleLengthRule: DispenseBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DispenseBundle) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DispenseBundleAllowedContactEmailRule: DispenseBundleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DispenseBundle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.contactEmail)) {
                return ["contact email \(item.contactEmail) is out of range"]
            }
            return []
        }
    }

    /// Runs every rule of a dispense bundle.
    final class DispenseBundleValidator {
        var rules: [any DispenseBundleRule]

        init(rules: [any DispenseBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: DispenseBundle) -> [String] {
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

        func requireValid(_ item: DispenseBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DispenseBundle]) -> [String: [String]] {
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

    static func defaultDispenseBundleValidator() -> DispenseBundleValidator {
        return DispenseBundleValidator(
            rules: [
                DispenseBundleContactEmailLengthRule(maxLength: 80),
                DispenseBundlePriorityRangeRule(min: 32, max: 64),
                DispenseBundleFloorValueRangeRule(min: 2.5, max: 3786.7),
                DispenseBundleTitleLengthRule(maxLength: 32),
                DispenseBundleAllowedContactEmailRule(allowed: ["capped", "strict", "strict"]),
            ]
        )
    }
}
