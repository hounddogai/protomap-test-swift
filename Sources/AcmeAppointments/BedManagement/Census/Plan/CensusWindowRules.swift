import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a census window must pass. Check returns its problems, or none.
    protocol CensusWindowRule {
        func check(_ item: CensusWindow) -> [String]
    }

    final class CensusWindowRequiredNameRule: CensusWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CensusWindow) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CensusWindowFloorValueRangeRule: CensusWindowRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CensusWindow) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CensusWindowRequiredCodeRule: CensusWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CensusWindow) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CensusWindowRequiredAllergyRule: CensusWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CensusWindow) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CensusWindowFacilityLengthRule: CensusWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CensusWindow) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CensusWindowCodePrefixRule: CensusWindowRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CensusWindow) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a census window.
    final class CensusWindowValidator {
        var rules: [any CensusWindowRule]

        init(rules: [any CensusWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: CensusWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CensusWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CensusWindow]) -> [String: [String]] {
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

    static func defaultCensusWindowValidator() -> CensusWindowValidator {
        return CensusWindowValidator(
            rules: [
                CensusWindowRequiredNameRule(message: "census window needs this field"),
                CensusWindowFloorValueRangeRule(min: 4.5, max: 708.4),
                CensusWindowRequiredCodeRule(message: "census window needs this field"),
                CensusWindowRequiredAllergyRule(message: "census window needs an entry"),
                CensusWindowFacilityLengthRule(maxLength: 120),
                CensusWindowCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
