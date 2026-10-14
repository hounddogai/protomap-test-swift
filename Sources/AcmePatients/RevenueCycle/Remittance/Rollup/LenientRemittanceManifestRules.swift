import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a lenient remittance manifest must pass. Check returns its problems, or none.
    protocol LenientRemittanceManifestRule {
        func check(_ item: LenientRemittanceManifest) -> [String]
    }

    final class LenientRemittanceManifestLimitRangeRule: LenientRemittanceManifestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientRemittanceManifest) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientRemittanceManifestCostRangeRule: LenientRemittanceManifestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientRemittanceManifest) -> [String] {
            let value = item.cost
            if value < min || value > max {
                return ["cost \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientRemittanceManifestPatientRefLengthRule: LenientRemittanceManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientRemittanceManifest) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientRemittanceManifestAllowedPatientRefRule: LenientRemittanceManifestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LenientRemittanceManifest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.patientRef)) {
                return ["patient ref \(item.patientRef) is expired"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient remittance manifest.
    final class LenientRemittanceManifestValidator {
        var rules: [any LenientRemittanceManifestRule]

        init(rules: [any LenientRemittanceManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientRemittanceManifest) -> [String] {
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

        func requireValid(_ item: LenientRemittanceManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientRemittanceManifest]) -> [String: [String]] {
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

    static func defaultLenientRemittanceManifestValidator() -> LenientRemittanceManifestValidator {
        return LenientRemittanceManifestValidator(
            rules: [
                LenientRemittanceManifestLimitRangeRule(min: 3600, max: 86400),
                LenientRemittanceManifestCostRangeRule(min: 7.4, max: 1563.5),
                LenientRemittanceManifestPatientRefLengthRule(maxLength: 80),
                LenientRemittanceManifestAllowedPatientRefRule(allowed: ["weighted", "default"]),
            ]
        )
    }
}
