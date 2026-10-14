import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a default cleaning preference is in its life cycle.
    enum DefaultCleaningPreferenceStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One default cleaning preference, with what the planners need to act on it.
    final class DefaultCleaningPreference {
        var code: String
        var title: String
        var diagnosisCode: String
        var archived: Bool
        var durationMinutes: Int
        var limit: Int
        var status: DefaultCleaningPreferenceStatus

        init(code: String, title: String, diagnosisCode: String, archived: Bool, durationMinutes: Int, limit: Int, status: DefaultCleaningPreferenceStatus) {
            self.code = code
            self.title = title
            self.diagnosisCode = diagnosisCode
            self.archived = archived
            self.durationMinutes = durationMinutes
            self.limit = limit
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DefaultCleaningPreferenceStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: DefaultCleaningPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default cleaning preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("default cleaning preference") \(code)"
        }

        func adjustedExposure() -> Double {
            return ((Double(durationMinutes) + Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> DefaultCleaningPreference {
            return DefaultCleaningPreference(
                code: code,
                title: title,
                diagnosisCode: diagnosisCode,
                archived: archived,
                durationMinutes: durationMinutes,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a default cleaning preference in status requested.
    static func newDefaultCleaningPreference(_ code: String, title: String) -> DefaultCleaningPreference {
        return DefaultCleaningPreference(
            code: code,
            title: title,
            diagnosisCode: "",
            archived: false,
            durationMinutes: 0,
            limit: 0,
            status: DefaultCleaningPreferenceStatus.requested
        )
    }
}
