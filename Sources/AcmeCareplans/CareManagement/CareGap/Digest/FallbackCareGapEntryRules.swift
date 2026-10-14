import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a fallback care gap entry must pass. Check returns its problems, or none.
    protocol FallbackCareGapEntryRule {
        func check(_ item: FallbackCareGapEntry) -> [String]
    }

    final class FallbackCareGapEntryTitleLengthRule: FallbackCareGapEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackCareGapEntry) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackCareGapEntryCurrencyLengthRule: FallbackCareGapEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackCareGapEntry) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackCareGapEntryAcuityRangeRule: FallbackCareGapEntryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackCareGapEntry) -> [String] {
            let value = item.acuity
            if value < min || value > max {
                return ["acuity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback care gap entry.
    final class FallbackCareGapEntryValidator {
        var rules: [any FallbackCareGapEntryRule]

        init(rules: [any FallbackCareGapEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackCareGapEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackCareGapEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackCareGapEntry]) -> [String: [String]] {
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

    static func defaultFallbackCareGapEntryValidator() -> FallbackCareGapEntryValidator {
        return FallbackCareGapEntryValidator(
            rules: [
                FallbackCareGapEntryTitleLengthRule(maxLength: 32),
                FallbackCareGapEntryCurrencyLengthRule(maxLength: 255),
                FallbackCareGapEntryAcuityRangeRule(min: 80, max: 255),
            ]
        )
    }
}
