import AcmePlatform
import Foundation

extension Consent {
    /// Where a capped language preference is in its life cycle.
    enum CappedLanguagePreferenceStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One capped language preference, with what the planners need to act on it.
    final class CappedLanguagePreference {
        var code: String
        var label: String
        var expiresAt: Int
        var ownerID: String
        var weight: Double
        var graceDays: Int
        var status: CappedLanguagePreferenceStatus

        init(code: String, label: String, expiresAt: Int, ownerID: String, weight: Double, graceDays: Int, status: CappedLanguagePreferenceStatus) {
            self.code = code
            self.label = label
            self.expiresAt = expiresAt
            self.ownerID = ownerID
            self.weight = weight
            self.graceDays = graceDays
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

        func canMoveTo(_ next: CappedLanguagePreferenceStatus) -> Bool {
            switch status {
            case .`open`:
                return next == CappedLanguagePreferenceStatus.resolved || next == CappedLanguagePreferenceStatus.reopened
            case .inReview:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == CappedLanguagePreferenceStatus.reopened || next == CappedLanguagePreferenceStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: CappedLanguagePreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped language preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func projectedValue() -> Double {
            return (Double(graceDays) * Double(expiresAt) * 100).rounded() / 100
        }

        func copyValue() -> CappedLanguagePreference {
            return CappedLanguagePreference(
                code: code,
                label: label,
                expiresAt: expiresAt,
                ownerID: ownerID,
                weight: weight,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a capped language preference in status open.
    static func newCappedLanguagePreference(_ code: String, label: String) -> CappedLanguagePreference {
        return CappedLanguagePreference(
            code: code,
            label: label,
            expiresAt: 0,
            ownerID: "",
            weight: 0.0,
            graceDays: 0,
            status: CappedLanguagePreferenceStatus.`open`
        )
    }
}
