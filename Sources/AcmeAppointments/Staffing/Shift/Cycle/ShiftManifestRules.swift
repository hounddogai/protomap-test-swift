import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a shift manifest must pass. Check returns its problems, or none.
    protocol ShiftManifestRule {
        func check(_ item: ShiftManifest) -> [String]
    }

    final class ShiftManifestRequiredSummaryRule: ShiftManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ShiftManifest) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ShiftManifestAllowedSummaryRule: ShiftManifestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ShiftManifest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.summary)) {
                return ["summary \(item.summary) is inconsistent"]
            }
            return []
        }
    }

    final class ShiftManifestWindowDaysRangeRule: ShiftManifestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ShiftManifest) -> [String] {
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

    final class ShiftManifestCodeLengthRule: ShiftManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ShiftManifest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a shift manifest.
    final class ShiftManifestValidator {
        var rules: [any ShiftManifestRule]

        init(rules: [any ShiftManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: ShiftManifest) -> [String] {
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

        func requireValid(_ item: ShiftManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ShiftManifest]) -> [String: [String]] {
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

    static func defaultShiftManifestValidator() -> ShiftManifestValidator {
        return ShiftManifestValidator(
            rules: [
                ShiftManifestRequiredSummaryRule(message: "shift manifest needs an entry"),
                ShiftManifestAllowedSummaryRule(allowed: ["capped"]),
                ShiftManifestWindowDaysRangeRule(min: 120, max: 3600),
                ShiftManifestCodeLengthRule(maxLength: 255),
            ]
        )
    }
}
