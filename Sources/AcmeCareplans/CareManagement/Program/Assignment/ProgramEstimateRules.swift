import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a program estimate must pass. Check returns its problems, or none.
    protocol ProgramEstimateRule {
        func check(_ item: ProgramEstimate) -> [String]
    }

    final class ProgramEstimateTitleLengthRule: ProgramEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProgramEstimate) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProgramEstimateCodePrefixRule: ProgramEstimateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ProgramEstimate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ProgramEstimateSegmentLengthRule: ProgramEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProgramEstimate) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProgramEstimateRetriesRangeRule: ProgramEstimateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ProgramEstimate) -> [String] {
            let value = item.retries
            var problems: [String] = []
            if value < min {
                problems.append("retries \(value) is below \(min)")
            }
            if value > max {
                problems.append("retries \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a program estimate.
    final class ProgramEstimateValidator {
        var rules: [any ProgramEstimateRule]

        init(rules: [any ProgramEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: ProgramEstimate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ProgramEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProgramEstimate]) -> [String: [String]] {
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

    static func defaultProgramEstimateValidator() -> ProgramEstimateValidator {
        return ProgramEstimateValidator(
            rules: [
                ProgramEstimateTitleLengthRule(maxLength: 16),
                ProgramEstimateCodePrefixRule(prefix: "ACM"),
                ProgramEstimateSegmentLengthRule(maxLength: 3600),
                ProgramEstimateRetriesRangeRule(min: 64, max: 64),
            ]
        )
    }
}
