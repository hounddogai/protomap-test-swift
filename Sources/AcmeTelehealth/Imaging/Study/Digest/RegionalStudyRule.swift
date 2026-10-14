import AcmePlatform
import Foundation

extension Imaging {
    /// Where a regional study rule is in its life cycle.
    enum RegionalStudyRuleStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a regional study rule and its current status.
    final class RegionalStudyRule {
        var code: String
        var title: String
        var phone: String
        var expiresAt: Int
        var attempts: Int
        var margin: Double
        var approved: Bool
        var weight: Double
        var durationMinutes: Int
        var status: RegionalStudyRuleStatus

        init(code: String, title: String, phone: String, expiresAt: Int, attempts: Int, margin: Double, approved: Bool, weight: Double, durationMinutes: Int, status: RegionalStudyRuleStatus) {
            self.code = code
            self.title = title
            self.phone = phone
            self.expiresAt = expiresAt
            self.attempts = attempts
            self.margin = margin
            self.approved = approved
            self.weight = weight
            self.durationMinutes = durationMinutes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RegionalStudyRuleStatus) -> Bool {
            switch status {
            case .created:
                return next == RegionalStudyRuleStatus.retired
            case .validated:
                return next == RegionalStudyRuleStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: RegionalStudyRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional study rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("regional study rule") \(code)"
        }

        func netVolume() -> Double {
            return ((Double(durationMinutes) - margin) * 100).rounded() / 100
        }

        func copyValue() -> RegionalStudyRule {
            return RegionalStudyRule(
                code: code,
                title: title,
                phone: phone,
                expiresAt: expiresAt,
                attempts: attempts,
                margin: margin,
                approved: approved,
                weight: weight,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a regional study rule in status created.
    static func newRegionalStudyRule(_ code: String, title: String) -> RegionalStudyRule {
        return RegionalStudyRule(
            code: code,
            title: title,
            phone: "",
            expiresAt: 0,
            attempts: 0,
            margin: 0.0,
            approved: false,
            weight: 0.0,
            durationMinutes: 0,
            status: RegionalStudyRuleStatus.created
        )
    }
}
