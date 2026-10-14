import AcmePlatform
import Foundation

extension Imaging {
    /// Where a seasonal priority rule is in its life cycle.
    enum SeasonalPriorityRuleStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a seasonal priority rule and its current status.
    final class SeasonalPriorityRule {
        var code: String
        var label: String
        var contactEmail: String
        var attributes: [String: String]
        var expiresAt: Int
        var maximum: Double
        var reviewer: String
        var windowDays: Int
        var graceDays: Int
        var attempts: Int
        var createdAt: Int
        var status: SeasonalPriorityRuleStatus

        init(code: String, label: String, contactEmail: String, attributes: [String: String], expiresAt: Int, maximum: Double, reviewer: String, windowDays: Int, graceDays: Int, attempts: Int, createdAt: Int, status: SeasonalPriorityRuleStatus) {
            self.code = code
            self.label = label
            self.contactEmail = contactEmail
            self.attributes = attributes
            self.expiresAt = expiresAt
            self.maximum = maximum
            self.reviewer = reviewer
            self.windowDays = windowDays
            self.graceDays = graceDays
            self.attempts = attempts
            self.createdAt = createdAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SeasonalPriorityRuleStatus) -> Bool {
            switch status {
            case .new:
                return next == SeasonalPriorityRuleStatus.failed
            case .queued:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == SeasonalPriorityRuleStatus.done || next == SeasonalPriorityRuleStatus.failed
            case .done:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalPriorityRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal priority rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("seasonal priority rule") \(code)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func netVolume() -> Double {
            return ((Double(attempts) + Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalPriorityRule {
            return SeasonalPriorityRule(
                code: code,
                label: label,
                contactEmail: contactEmail,
                attributes: attributes,
                expiresAt: expiresAt,
                maximum: maximum,
                reviewer: reviewer,
                windowDays: windowDays,
                graceDays: graceDays,
                attempts: attempts,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a seasonal priority rule in status new.
    static func newSeasonalPriorityRule(_ code: String, label: String) -> SeasonalPriorityRule {
        return SeasonalPriorityRule(
            code: code,
            label: label,
            contactEmail: "",
            attributes: [:],
            expiresAt: 0,
            maximum: 0.0,
            reviewer: "",
            windowDays: 0,
            graceDays: 0,
            attempts: 0,
            createdAt: 0,
            status: SeasonalPriorityRuleStatus.new
        )
    }
}
