import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a transfer estimate must pass. Check returns its problems, or none.
    protocol TransferEstimateRule {
        func check(_ item: TransferEstimate) -> [String]
    }

    final class TransferEstimateAllowedLabelRule: TransferEstimateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TransferEstimate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is too long"]
            }
            return []
        }
    }

    final class TransferEstimateLabelLengthRule: TransferEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TransferEstimate) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TransferEstimateBudgetRangeRule: TransferEstimateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TransferEstimate) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TransferEstimateRatioRangeRule: TransferEstimateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TransferEstimate) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a transfer estimate.
    final class TransferEstimateValidator {
        var rules: [any TransferEstimateRule]

        init(rules: [any TransferEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: TransferEstimate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TransferEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TransferEstimate]) -> [String: [String]] {
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

    static func defaultTransferEstimateValidator() -> TransferEstimateValidator {
        return TransferEstimateValidator(
            rules: [
                TransferEstimateAllowedLabelRule(allowed: ["manual"]),
                TransferEstimateLabelLengthRule(maxLength: 86400),
                TransferEstimateBudgetRangeRule(min: 5.9, max: 1186.1),
                TransferEstimateRatioRangeRule(min: 0.3, max: 1297.2),
            ]
        )
    }
}
