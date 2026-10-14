import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a order set rollup must pass. Check returns its problems, or none.
    protocol OrderSetRollupRule {
        func check(_ item: OrderSetRollup) -> [String]
    }

    final class OrderSetRollupCodeLengthRule: OrderSetRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OrderSetRollup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OrderSetRollupPatientRefLengthRule: OrderSetRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OrderSetRollup) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OrderSetRollupTitleLengthRule: OrderSetRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OrderSetRollup) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OrderSetRollupVisibleGuardRule: OrderSetRollupRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: OrderSetRollup) -> [String] {
            if item.visible && (item.ratio > limit) {
                return ["ratio \(item.ratio) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class OrderSetRollupRequiredTitleRule: OrderSetRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OrderSetRollup) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OrderSetRollupRequiredSourceRule: OrderSetRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OrderSetRollup) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a order set rollup.
    final class OrderSetRollupValidator {
        var rules: [any OrderSetRollupRule]

        init(rules: [any OrderSetRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: OrderSetRollup) -> [String] {
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

        func requireValid(_ item: OrderSetRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OrderSetRollup]) -> [String: [String]] {
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

    static func defaultOrderSetRollupValidator() -> OrderSetRollupValidator {
        return OrderSetRollupValidator(
            rules: [
                OrderSetRollupCodeLengthRule(maxLength: 16),
                OrderSetRollupPatientRefLengthRule(maxLength: 255),
                OrderSetRollupTitleLengthRule(maxLength: 255),
                OrderSetRollupVisibleGuardRule(limit: 8.5),
                OrderSetRollupRequiredTitleRule(message: "order set rollup needs an entry"),
                OrderSetRollupRequiredSourceRule(message: "order set rollup needs this field"),
            ]
        )
    }
}
