import AcmePlatform
import Foundation

extension Labs {
    /// A rule a primary courier manifest must pass. Check returns its problems, or none.
    protocol PrimaryCourierManifestRule {
        func check(_ item: PrimaryCourierManifest) -> [String]
    }

    final class PrimaryCourierManifestTitleLengthRule: PrimaryCourierManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryCourierManifest) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryCourierManifestRequiredSpecialtyRule: PrimaryCourierManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryCourierManifest) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryCourierManifestRequiredCodeRule: PrimaryCourierManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryCourierManifest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryCourierManifestSpecialtyLengthRule: PrimaryCourierManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryCourierManifest) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryCourierManifestUnitLengthRule: PrimaryCourierManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryCourierManifest) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryCourierManifestRateRangeRule: PrimaryCourierManifestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryCourierManifest) -> [String] {
            let value = item.rate
            var problems: [String] = []
            if value < min {
                problems.append("rate \(value) is below \(min)")
            }
            if value > max {
                problems.append("rate \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a primary courier manifest.
    final class PrimaryCourierManifestValidator {
        var rules: [any PrimaryCourierManifestRule]

        init(rules: [any PrimaryCourierManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryCourierManifest) -> [String] {
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

        func requireValid(_ item: PrimaryCourierManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryCourierManifest]) -> [String: [String]] {
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

    static func defaultPrimaryCourierManifestValidator() -> PrimaryCourierManifestValidator {
        return PrimaryCourierManifestValidator(
            rules: [
                PrimaryCourierManifestTitleLengthRule(maxLength: 86400),
                PrimaryCourierManifestRequiredSpecialtyRule(message: "primary courier manifest needs an entry"),
                PrimaryCourierManifestRequiredCodeRule(message: "primary courier manifest needs a value"),
                PrimaryCourierManifestSpecialtyLengthRule(maxLength: 120),
                PrimaryCourierManifestUnitLengthRule(maxLength: 1000),
                PrimaryCourierManifestRateRangeRule(min: 9.2, max: 1967.9),
            ]
        )
    }
}
