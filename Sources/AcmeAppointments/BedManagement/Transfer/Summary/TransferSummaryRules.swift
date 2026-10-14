import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a transfer summary must pass. Check returns its problems, or none.
    protocol TransferSummaryRule {
        func check(_ item: TransferSummary) -> [String]
    }

    final class TransferSummaryAllowedTitleRule: TransferSummaryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TransferSummary) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is expired"]
            }
            return []
        }
    }

    final class TransferSummaryChecksumLengthRule: TransferSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TransferSummary) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TransferSummaryLimitRangeRule: TransferSummaryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TransferSummary) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a transfer summary.
    final class TransferSummaryValidator {
        var rules: [any TransferSummaryRule]

        init(rules: [any TransferSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: TransferSummary) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TransferSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TransferSummary]) -> [String: [String]] {
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

    static func defaultTransferSummaryValidator() -> TransferSummaryValidator {
        return TransferSummaryValidator(
            rules: [
                TransferSummaryAllowedTitleRule(allowed: []),
                TransferSummaryChecksumLengthRule(maxLength: 255),
                TransferSummaryLimitRangeRule(min: 64, max: 120),
            ]
        )
    }
}
