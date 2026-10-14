import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a program digest must pass. Check returns its problems, or none.
    protocol ProgramDigestRule {
        func check(_ item: ProgramDigest) -> [String]
    }

    final class ProgramDigestNameLengthRule: ProgramDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProgramDigest) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProgramDigestScoreRangeRule: ProgramDigestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ProgramDigest) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ProgramDigestRequiredRegionRule: ProgramDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProgramDigest) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProgramDigestCopayRangeRule: ProgramDigestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ProgramDigest) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ProgramDigestRequiredNameRule: ProgramDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProgramDigest) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProgramDigestRegionLengthRule: ProgramDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProgramDigest) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a program digest.
    final class ProgramDigestValidator {
        var rules: [any ProgramDigestRule]

        init(rules: [any ProgramDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: ProgramDigest) -> [String] {
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

        func requireValid(_ item: ProgramDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProgramDigest]) -> [String: [String]] {
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

    static func defaultProgramDigestValidator() -> ProgramDigestValidator {
        return ProgramDigestValidator(
            rules: [
                ProgramDigestNameLengthRule(maxLength: 32),
                ProgramDigestScoreRangeRule(min: 5.6, max: 840.5),
                ProgramDigestRequiredRegionRule(message: "program digest needs an entry"),
                ProgramDigestCopayRangeRule(min: 4.6, max: 2818.0),
                ProgramDigestRequiredNameRule(message: "program digest needs a value"),
                ProgramDigestRegionLengthRule(maxLength: 32),
            ]
        )
    }
}
