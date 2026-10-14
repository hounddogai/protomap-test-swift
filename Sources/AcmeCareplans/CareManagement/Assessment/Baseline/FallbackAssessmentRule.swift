import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a fallback assessment rule is in its life cycle.
    enum FallbackAssessmentRuleStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a fallback assessment rule and its current status.
    final class FallbackAssessmentRule {
        var code: String
        var name: String
        var locale: String
        var floorValue: Double
        var tags: [String]
        var version: Int
        var allergy: String
        var rate: Double
        var externalRef: String
        var margin: Double
        var updatedAt: Int
        var status: FallbackAssessmentRuleStatus

        init(code: String, name: String, locale: String, floorValue: Double, tags: [String], version: Int, allergy: String, rate: Double, externalRef: String, margin: Double, updatedAt: Int, status: FallbackAssessmentRuleStatus) {
            self.code = code
            self.name = name
            self.locale = locale
            self.floorValue = floorValue
            self.tags = tags
            self.version = version
            self.allergy = allergy
            self.rate = rate
            self.externalRef = externalRef
            self.margin = margin
            self.updatedAt = updatedAt
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

        func canMoveTo(_ next: FallbackAssessmentRuleStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == FallbackAssessmentRuleStatus.failed
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == FallbackAssessmentRuleStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackAssessmentRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback assessment rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func adjustedExposure() -> Double {
            return (Double(version) * rate * 100).rounded() / 100
        }

        func copyValue() -> FallbackAssessmentRule {
            return FallbackAssessmentRule(
                code: code,
                name: name,
                locale: locale,
                floorValue: floorValue,
                tags: tags,
                version: version,
                allergy: allergy,
                rate: rate,
                externalRef: externalRef,
                margin: margin,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a fallback assessment rule in status new.
    static func newFallbackAssessmentRule(_ code: String, name: String) -> FallbackAssessmentRule {
        return FallbackAssessmentRule(
            code: code,
            name: name,
            locale: "",
            floorValue: 0.0,
            tags: [],
            version: 0,
            allergy: "",
            rate: 0.0,
            externalRef: "",
            margin: 0.0,
            updatedAt: 0,
            status: FallbackAssessmentRuleStatus.new
        )
    }
}
