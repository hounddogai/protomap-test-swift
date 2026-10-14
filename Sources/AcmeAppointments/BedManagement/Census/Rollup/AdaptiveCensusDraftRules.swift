import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a adaptive census draft must pass. Check returns its problems, or none.
    protocol AdaptiveCensusDraftRule {
        func check(_ item: AdaptiveCensusDraft) -> [String]
    }

    final class AdaptiveCensusDraftRequiredLabelRule: AdaptiveCensusDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveCensusDraft) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveCensusDraftAcuityRangeRule: AdaptiveCensusDraftRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveCensusDraft) -> [String] {
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

    final class AdaptiveCensusDraftCodePrefixRule: AdaptiveCensusDraftRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveCensusDraft) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AdaptiveCensusDraftChecksumLengthRule: AdaptiveCensusDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveCensusDraft) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive census draft.
    final class AdaptiveCensusDraftValidator {
        var rules: [any AdaptiveCensusDraftRule]

        init(rules: [any AdaptiveCensusDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveCensusDraft) -> [String] {
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

        func requireValid(_ item: AdaptiveCensusDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveCensusDraft]) -> [String: [String]] {
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

    static func defaultAdaptiveCensusDraftValidator() -> AdaptiveCensusDraftValidator {
        return AdaptiveCensusDraftValidator(
            rules: [
                AdaptiveCensusDraftRequiredLabelRule(message: "adaptive census draft needs an entry"),
                AdaptiveCensusDraftAcuityRangeRule(min: 120, max: 120),
                AdaptiveCensusDraftCodePrefixRule(prefix: "REF"),
                AdaptiveCensusDraftChecksumLengthRule(maxLength: 86400),
            ]
        )
    }
}
