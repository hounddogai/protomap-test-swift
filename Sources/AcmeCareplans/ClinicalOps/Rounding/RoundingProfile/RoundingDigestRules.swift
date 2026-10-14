import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a rounding digest must pass. Check returns its problems, or none.
    protocol RoundingDigestRule {
        func check(_ item: RoundingDigest) -> [String]
    }

    final class RoundingDigestThresholdRangeRule: RoundingDigestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RoundingDigest) -> [String] {
            let value = item.threshold
            var problems: [String] = []
            if value < min {
                problems.append("threshold \(value) is below \(min)")
            }
            if value > max {
                problems.append("threshold \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RoundingDigestRegionLengthRule: RoundingDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RoundingDigest) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RoundingDigestActiveGuardRule: RoundingDigestRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: RoundingDigest) -> [String] {
            if item.active && (item.sequence > limit) {
                return ["sequence \(item.sequence) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class RoundingDigestRequiredClinicianIDRule: RoundingDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RoundingDigest) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RoundingDigestNameLengthRule: RoundingDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RoundingDigest) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a rounding digest.
    final class RoundingDigestValidator {
        var rules: [any RoundingDigestRule]

        init(rules: [any RoundingDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: RoundingDigest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RoundingDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RoundingDigest]) -> [String: [String]] {
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

    static func defaultRoundingDigestValidator() -> RoundingDigestValidator {
        return RoundingDigestValidator(
            rules: [
                RoundingDigestThresholdRangeRule(min: 7.0, max: 4170.8),
                RoundingDigestRegionLengthRule(maxLength: 3600),
                RoundingDigestActiveGuardRule(limit: 86400),
                RoundingDigestRequiredClinicianIDRule(message: "rounding digest needs this field"),
                RoundingDigestNameLengthRule(maxLength: 86400),
            ]
        )
    }
}
