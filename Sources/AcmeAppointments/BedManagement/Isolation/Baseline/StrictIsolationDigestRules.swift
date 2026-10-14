import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a strict isolation digest must pass. Check returns its problems, or none.
    protocol StrictIsolationDigestRule {
        func check(_ item: StrictIsolationDigest) -> [String]
    }

    final class StrictIsolationDigestFloorValueRangeRule: StrictIsolationDigestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictIsolationDigest) -> [String] {
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

    final class StrictIsolationDigestClinicianIDLengthRule: StrictIsolationDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictIsolationDigest) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictIsolationDigestTitleLengthRule: StrictIsolationDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictIsolationDigest) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictIsolationDigestCodePrefixRule: StrictIsolationDigestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StrictIsolationDigest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict isolation digest.
    final class StrictIsolationDigestValidator {
        var rules: [any StrictIsolationDigestRule]

        init(rules: [any StrictIsolationDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictIsolationDigest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictIsolationDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictIsolationDigest]) -> [String: [String]] {
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

    static func defaultStrictIsolationDigestValidator() -> StrictIsolationDigestValidator {
        return StrictIsolationDigestValidator(
            rules: [
                StrictIsolationDigestFloorValueRangeRule(min: 0.8, max: 3566.0),
                StrictIsolationDigestClinicianIDLengthRule(maxLength: 86400),
                StrictIsolationDigestTitleLengthRule(maxLength: 3600),
                StrictIsolationDigestCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
