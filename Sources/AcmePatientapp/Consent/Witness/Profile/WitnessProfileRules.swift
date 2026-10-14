import AcmePlatform
import Foundation

extension Consent {
    /// A rule a witness profile must pass. Check returns its problems, or none.
    protocol WitnessProfileRule {
        func check(_ item: WitnessProfile) -> [String]
    }

    final class WitnessProfileWindowDaysRangeRule: WitnessProfileRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WitnessProfile) -> [String] {
            let value = item.windowDays
            if value < min || value > max {
                return ["window days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WitnessProfileCodeLengthRule: WitnessProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WitnessProfile) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WitnessProfileSegmentLengthRule: WitnessProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WitnessProfile) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WitnessProfileAllowedTimezoneRule: WitnessProfileRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WitnessProfile) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.timezone)) {
                return ["timezone \(item.timezone) is duplicated"]
            }
            return []
        }
    }

    final class WitnessProfilePhoneLengthRule: WitnessProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WitnessProfile) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a witness profile.
    final class WitnessProfileValidator {
        var rules: [any WitnessProfileRule]

        init(rules: [any WitnessProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: WitnessProfile) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WitnessProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WitnessProfile]) -> [String: [String]] {
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

    static func defaultWitnessProfileValidator() -> WitnessProfileValidator {
        return WitnessProfileValidator(
            rules: [
                WitnessProfileWindowDaysRangeRule(min: 32, max: 120),
                WitnessProfileCodeLengthRule(maxLength: 255),
                WitnessProfileSegmentLengthRule(maxLength: 16),
                WitnessProfileAllowedTimezoneRule(allowed: ["weighted"]),
                WitnessProfilePhoneLengthRule(maxLength: 80),
            ]
        )
    }
}
