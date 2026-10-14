import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a fallback handoff threshold is in its life cycle.
    enum FallbackHandoffThresholdStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A fallback handoff threshold as the handoff team keeps it.
    final class FallbackHandoffThreshold {
        var code: String
        var title: String
        var locale: String
        var approved: Bool
        var attributes: [String: String]
        var score: Double
        var durationMinutes: Int
        var status: FallbackHandoffThresholdStatus

        init(code: String, title: String, locale: String, approved: Bool, attributes: [String: String], score: Double, durationMinutes: Int, status: FallbackHandoffThresholdStatus) {
            self.code = code
            self.title = title
            self.locale = locale
            self.approved = approved
            self.attributes = attributes
            self.score = score
            self.durationMinutes = durationMinutes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FallbackHandoffThresholdStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == FallbackHandoffThresholdStatus.reopened || next == FallbackHandoffThresholdStatus.archived
            case .reopened:
                return next == FallbackHandoffThresholdStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackHandoffThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback handoff threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
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
            return (score * Double(durationMinutes) * 100).rounded() / 100
        }

        func copyValue() -> FallbackHandoffThreshold {
            return FallbackHandoffThreshold(
                code: code,
                title: title,
                locale: locale,
                approved: approved,
                attributes: attributes,
                score: score,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a fallback handoff threshold in status open.
    static func newFallbackHandoffThreshold(_ code: String, title: String) -> FallbackHandoffThreshold {
        return FallbackHandoffThreshold(
            code: code,
            title: title,
            locale: "",
            approved: false,
            attributes: [:],
            score: 0.0,
            durationMinutes: 0,
            status: FallbackHandoffThresholdStatus.`open`
        )
    }
}
