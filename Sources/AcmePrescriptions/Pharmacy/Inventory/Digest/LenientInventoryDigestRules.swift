import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a lenient inventory digest must pass. Check returns its problems, or none.
    protocol LenientInventoryDigestRule {
        func check(_ item: LenientInventoryDigest) -> [String]
    }

    final class LenientInventoryDigestAcuityRangeRule: LenientInventoryDigestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientInventoryDigest) -> [String] {
            let value = item.acuity
            if value < min || value > max {
                return ["acuity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientInventoryDigestRequiredCodeRule: LenientInventoryDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientInventoryDigest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientInventoryDigestCodePrefixRule: LenientInventoryDigestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LenientInventoryDigest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LenientInventoryDigestSequenceRangeRule: LenientInventoryDigestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientInventoryDigest) -> [String] {
            let value = item.sequence
            if value < min || value > max {
                return ["sequence \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientInventoryDigestCodeLengthRule: LenientInventoryDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientInventoryDigest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientInventoryDigestRequiredLabelRule: LenientInventoryDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientInventoryDigest) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a lenient inventory digest.
    final class LenientInventoryDigestValidator {
        var rules: [any LenientInventoryDigestRule]

        init(rules: [any LenientInventoryDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientInventoryDigest) -> [String] {
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

        func requireValid(_ item: LenientInventoryDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientInventoryDigest]) -> [String: [String]] {
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

    static func defaultLenientInventoryDigestValidator() -> LenientInventoryDigestValidator {
        return LenientInventoryDigestValidator(
            rules: [
                LenientInventoryDigestAcuityRangeRule(min: 16, max: 32),
                LenientInventoryDigestRequiredCodeRule(message: "lenient inventory digest needs this field"),
                LenientInventoryDigestCodePrefixRule(prefix: "ACM"),
                LenientInventoryDigestSequenceRangeRule(min: 16, max: 120),
                LenientInventoryDigestCodeLengthRule(maxLength: 32),
                LenientInventoryDigestRequiredLabelRule(message: "lenient inventory digest needs this field"),
            ]
        )
    }
}
