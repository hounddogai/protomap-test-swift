import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a default closure bundle must pass. Check returns its problems, or none.
    protocol DefaultClosureBundleRule {
        func check(_ item: DefaultClosureBundle) -> [String]
    }

    final class DefaultClosureBundleFloorValueRangeRule: DefaultClosureBundleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultClosureBundle) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultClosureBundleDiagnosisCodeLengthRule: DefaultClosureBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultClosureBundle) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultClosureBundleCodePrefixRule: DefaultClosureBundleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DefaultClosureBundle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DefaultClosureBundleAcuityRangeRule: DefaultClosureBundleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultClosureBundle) -> [String] {
            let value = item.acuity
            var problems: [String] = []
            if value < min {
                problems.append("acuity \(value) is below \(min)")
            }
            if value > max {
                problems.append("acuity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DefaultClosureBundleChecksumLengthRule: DefaultClosureBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultClosureBundle) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a default closure bundle.
    final class DefaultClosureBundleValidator {
        var rules: [any DefaultClosureBundleRule]

        init(rules: [any DefaultClosureBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultClosureBundle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultClosureBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultClosureBundle]) -> [String: [String]] {
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

    static func defaultDefaultClosureBundleValidator() -> DefaultClosureBundleValidator {
        return DefaultClosureBundleValidator(
            rules: [
                DefaultClosureBundleFloorValueRangeRule(min: 7.2, max: 344.9),
                DefaultClosureBundleDiagnosisCodeLengthRule(maxLength: 255),
                DefaultClosureBundleCodePrefixRule(prefix: "OPS"),
                DefaultClosureBundleAcuityRangeRule(min: 120, max: 3600),
                DefaultClosureBundleChecksumLengthRule(maxLength: 86400),
            ]
        )
    }
}
