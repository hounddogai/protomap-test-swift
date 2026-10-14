import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a strict bed board variance must pass. Check returns its problems, or none.
    protocol StrictBedBoardVarianceRule {
        func check(_ item: StrictBedBoardVariance) -> [String]
    }

    final class StrictBedBoardVariancePhoneLengthRule: StrictBedBoardVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictBedBoardVariance) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictBedBoardVarianceCurrencyLengthRule: StrictBedBoardVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictBedBoardVariance) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictBedBoardVarianceAllowedCodeRule: StrictBedBoardVarianceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StrictBedBoardVariance) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is above maximum"]
            }
            return []
        }
    }

    final class StrictBedBoardVarianceNameLengthRule: StrictBedBoardVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictBedBoardVariance) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict bed board variance.
    final class StrictBedBoardVarianceValidator {
        var rules: [any StrictBedBoardVarianceRule]

        init(rules: [any StrictBedBoardVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictBedBoardVariance) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictBedBoardVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictBedBoardVariance]) -> [String: [String]] {
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

    static func defaultStrictBedBoardVarianceValidator() -> StrictBedBoardVarianceValidator {
        return StrictBedBoardVarianceValidator(
            rules: [
                StrictBedBoardVariancePhoneLengthRule(maxLength: 255),
                StrictBedBoardVarianceCurrencyLengthRule(maxLength: 16),
                StrictBedBoardVarianceAllowedCodeRule(allowed: []),
                StrictBedBoardVarianceNameLengthRule(maxLength: 80),
            ]
        )
    }
}
