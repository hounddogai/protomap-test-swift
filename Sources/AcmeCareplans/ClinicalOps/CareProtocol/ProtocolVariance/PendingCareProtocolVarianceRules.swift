import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a pending care protocol variance must pass. Check returns its problems, or none.
    protocol PendingCareProtocolVarianceRule {
        func check(_ item: PendingCareProtocolVariance) -> [String]
    }

    final class PendingCareProtocolVarianceRequiredRegionRule: PendingCareProtocolVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingCareProtocolVariance) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingCareProtocolVarianceCodePrefixRule: PendingCareProtocolVarianceRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PendingCareProtocolVariance) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PendingCareProtocolVarianceDurationMinutesRangeRule: PendingCareProtocolVarianceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingCareProtocolVariance) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingCareProtocolVarianceVisibleGuardRule: PendingCareProtocolVarianceRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: PendingCareProtocolVariance) -> [String] {
            if item.visible && (item.floorValue > limit) {
                return ["floor value \(item.floorValue) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    /// Runs every rule of a pending care protocol variance.
    final class PendingCareProtocolVarianceValidator {
        var rules: [any PendingCareProtocolVarianceRule]

        init(rules: [any PendingCareProtocolVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingCareProtocolVariance) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingCareProtocolVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingCareProtocolVariance]) -> [String: [String]] {
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

    static func defaultPendingCareProtocolVarianceValidator() -> PendingCareProtocolVarianceValidator {
        return PendingCareProtocolVarianceValidator(
            rules: [
                PendingCareProtocolVarianceRequiredRegionRule(
                    message: "pending care protocol variance needs this field"
                ),
                PendingCareProtocolVarianceCodePrefixRule(prefix: "X"),
                PendingCareProtocolVarianceDurationMinutesRangeRule(min: 80, max: 1000),
                PendingCareProtocolVarianceVisibleGuardRule(limit: 4.3),
            ]
        )
    }
}
