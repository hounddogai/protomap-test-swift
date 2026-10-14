import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a strict program manifest must pass. Check returns its problems, or none.
    protocol StrictProgramManifestRule {
        func check(_ item: StrictProgramManifest) -> [String]
    }

    final class StrictProgramManifestRequiredOwnerIDRule: StrictProgramManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictProgramManifest) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictProgramManifestBudgetRangeRule: StrictProgramManifestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictProgramManifest) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StrictProgramManifestRequiredUnitRule: StrictProgramManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictProgramManifest) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictProgramManifestStartsAtRangeRule: StrictProgramManifestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictProgramManifest) -> [String] {
            let value = item.startsAt
            if value < min || value > max {
                return ["starts at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StrictProgramManifestUnitLengthRule: StrictProgramManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictProgramManifest) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict program manifest.
    final class StrictProgramManifestValidator {
        var rules: [any StrictProgramManifestRule]

        init(rules: [any StrictProgramManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictProgramManifest) -> [String] {
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

        func requireValid(_ item: StrictProgramManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictProgramManifest]) -> [String: [String]] {
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

    static func defaultStrictProgramManifestValidator() -> StrictProgramManifestValidator {
        return StrictProgramManifestValidator(
            rules: [
                StrictProgramManifestRequiredOwnerIDRule(message: "strict program manifest needs this field"),
                StrictProgramManifestBudgetRangeRule(min: 4.6, max: 4841.7),
                StrictProgramManifestRequiredUnitRule(message: "strict program manifest needs this field"),
                StrictProgramManifestStartsAtRangeRule(min: 255, max: 1000),
                StrictProgramManifestUnitLengthRule(maxLength: 80),
            ]
        )
    }
}
