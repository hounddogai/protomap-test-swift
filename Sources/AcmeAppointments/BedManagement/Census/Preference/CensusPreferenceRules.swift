import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a census preference must pass. Check returns its problems, or none.
    protocol CensusPreferenceRule {
        func check(_ item: CensusPreference) -> [String]
    }

    final class CensusPreferenceFloorValueRangeRule: CensusPreferenceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CensusPreference) -> [String] {
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

    final class CensusPreferenceVisibleGuardRule: CensusPreferenceRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: CensusPreference) -> [String] {
            if item.visible && (item.floorValue > limit) {
                return ["floor value \(item.floorValue) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class CensusPreferenceTimezoneLengthRule: CensusPreferenceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CensusPreference) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CensusPreferenceRequiredTitleRule: CensusPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CensusPreference) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CensusPreferenceRequiredTimezoneRule: CensusPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CensusPreference) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CensusPreferenceCodePrefixRule: CensusPreferenceRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CensusPreference) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a census preference.
    final class CensusPreferenceValidator {
        var rules: [any CensusPreferenceRule]

        init(rules: [any CensusPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: CensusPreference) -> [String] {
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

        func requireValid(_ item: CensusPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CensusPreference]) -> [String: [String]] {
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

    static func defaultCensusPreferenceValidator() -> CensusPreferenceValidator {
        return CensusPreferenceValidator(
            rules: [
                CensusPreferenceFloorValueRangeRule(min: 1.5, max: 827.3),
                CensusPreferenceVisibleGuardRule(limit: 1.9),
                CensusPreferenceTimezoneLengthRule(maxLength: 64),
                CensusPreferenceRequiredTitleRule(message: "census preference needs a value"),
                CensusPreferenceRequiredTimezoneRule(message: "census preference needs a value"),
                CensusPreferenceCodePrefixRule(prefix: "X"),
            ]
        )
    }
}
