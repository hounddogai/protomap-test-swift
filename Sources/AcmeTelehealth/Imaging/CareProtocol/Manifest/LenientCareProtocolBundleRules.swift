import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a lenient care protocol bundle must pass. Check returns its problems, or none.
    protocol LenientCareProtocolBundleRule {
        func check(_ item: LenientCareProtocolBundle) -> [String]
    }

    final class LenientCareProtocolBundleCodeLengthRule: LenientCareProtocolBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientCareProtocolBundle) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientCareProtocolBundleProcedureCodeLengthRule: LenientCareProtocolBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientCareProtocolBundle) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientCareProtocolBundleStartsAtRangeRule: LenientCareProtocolBundleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientCareProtocolBundle) -> [String] {
            let value = item.startsAt
            var problems: [String] = []
            if value < min {
                problems.append("starts at \(value) is below \(min)")
            }
            if value > max {
                problems.append("starts at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LenientCareProtocolBundleAttemptsRangeRule: LenientCareProtocolBundleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientCareProtocolBundle) -> [String] {
            let value = item.attempts
            var problems: [String] = []
            if value < min {
                problems.append("attempts \(value) is below \(min)")
            }
            if value > max {
                problems.append("attempts \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LenientCareProtocolBundleChecksumLengthRule: LenientCareProtocolBundleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientCareProtocolBundle) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient care protocol bundle.
    final class LenientCareProtocolBundleValidator {
        var rules: [any LenientCareProtocolBundleRule]

        init(rules: [any LenientCareProtocolBundleRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientCareProtocolBundle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientCareProtocolBundle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientCareProtocolBundle]) -> [String: [String]] {
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

    static func defaultLenientCareProtocolBundleValidator() -> LenientCareProtocolBundleValidator {
        return LenientCareProtocolBundleValidator(
            rules: [
                LenientCareProtocolBundleCodeLengthRule(maxLength: 120),
                LenientCareProtocolBundleProcedureCodeLengthRule(maxLength: 3600),
                LenientCareProtocolBundleStartsAtRangeRule(min: 16, max: 86400),
                LenientCareProtocolBundleAttemptsRangeRule(min: 16, max: 80),
                LenientCareProtocolBundleChecksumLengthRule(maxLength: 32),
            ]
        )
    }
}
