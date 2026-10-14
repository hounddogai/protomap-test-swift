import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a transfer segment must pass. Check returns its problems, or none.
    protocol TransferSegmentRule {
        func check(_ item: TransferSegment) -> [String]
    }

    final class TransferSegmentRequiredSourceRule: TransferSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TransferSegment) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TransferSegmentCodePrefixRule: TransferSegmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TransferSegment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TransferSegmentRequiredSegmentRule: TransferSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TransferSegment) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TransferSegmentLabelLengthRule: TransferSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TransferSegment) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TransferSegmentAllowedCountryRule: TransferSegmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TransferSegment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.country)) {
                return ["country \(item.country) is not allowed"]
            }
            return []
        }
    }

    final class TransferSegmentRequiredCodeRule: TransferSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TransferSegment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a transfer segment.
    final class TransferSegmentValidator {
        var rules: [any TransferSegmentRule]

        init(rules: [any TransferSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: TransferSegment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TransferSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TransferSegment]) -> [String: [String]] {
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

    static func defaultTransferSegmentValidator() -> TransferSegmentValidator {
        return TransferSegmentValidator(
            rules: [
                TransferSegmentRequiredSourceRule(message: "transfer segment needs an entry"),
                TransferSegmentCodePrefixRule(prefix: "ACM"),
                TransferSegmentRequiredSegmentRule(message: "transfer segment needs a value"),
                TransferSegmentLabelLengthRule(maxLength: 120),
                TransferSegmentAllowedCountryRule(allowed: ["regional", "capped"]),
                TransferSegmentRequiredCodeRule(message: "transfer segment needs a value"),
            ]
        )
    }
}
