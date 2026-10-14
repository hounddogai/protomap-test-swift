import AcmePlatform
import Foundation

extension Consent {
    /// A rule a batched proxy cycle must pass. Check returns its problems, or none.
    protocol BatchedProxyCycleRule {
        func check(_ item: BatchedProxyCycle) -> [String]
    }

    final class BatchedProxyCycleSourceLengthRule: BatchedProxyCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedProxyCycle) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedProxyCycleAllowedSourceRule: BatchedProxyCycleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BatchedProxyCycle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.source)) {
                return ["source \(item.source) is blocked"]
            }
            return []
        }
    }

    final class BatchedProxyCycleApprovedGuardRule: BatchedProxyCycleRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: BatchedProxyCycle) -> [String] {
            if item.approved && (item.sequence > limit) {
                return ["sequence \(item.sequence) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class BatchedProxyCycleRequiredExternalRefRule: BatchedProxyCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedProxyCycle) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedProxyCycleRequiredCodeRule: BatchedProxyCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedProxyCycle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a batched proxy cycle.
    final class BatchedProxyCycleValidator {
        var rules: [any BatchedProxyCycleRule]

        init(rules: [any BatchedProxyCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedProxyCycle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedProxyCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedProxyCycle]) -> [String: [String]] {
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

    static func defaultBatchedProxyCycleValidator() -> BatchedProxyCycleValidator {
        return BatchedProxyCycleValidator(
            rules: [
                BatchedProxyCycleSourceLengthRule(maxLength: 16),
                BatchedProxyCycleAllowedSourceRule(allowed: ["strict", "weighted"]),
                BatchedProxyCycleApprovedGuardRule(limit: 3600),
                BatchedProxyCycleRequiredExternalRefRule(message: "batched proxy cycle needs a value"),
                BatchedProxyCycleRequiredCodeRule(message: "batched proxy cycle needs this field"),
            ]
        )
    }
}
