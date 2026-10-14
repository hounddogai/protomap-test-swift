import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a seasonal goal draft is in its life cycle.
    enum SeasonalGoalDraftStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A seasonal goal draft as the goal team keeps it.
    final class SeasonalGoalDraft {
        var code: String
        var label: String
        var version: Int
        var phone: String
        var windowDays: Int
        var description: String
        var updatedAt: Int
        var status: SeasonalGoalDraftStatus

        init(code: String, label: String, version: Int, phone: String, windowDays: Int, description: String, updatedAt: Int, status: SeasonalGoalDraftStatus) {
            self.code = code
            self.label = label
            self.version = version
            self.phone = phone
            self.windowDays = windowDays
            self.description = description
            self.updatedAt = updatedAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SeasonalGoalDraftStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == SeasonalGoalDraftStatus.rejected
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: SeasonalGoalDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal goal draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func netValue() -> Double {
            return ((Double(version) - Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalGoalDraft {
            return SeasonalGoalDraft(
                code: code,
                label: label,
                version: version,
                phone: phone,
                windowDays: windowDays,
                description: description,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a seasonal goal draft in status proposed.
    static func newSeasonalGoalDraft(_ code: String, label: String) -> SeasonalGoalDraft {
        return SeasonalGoalDraft(
            code: code,
            label: label,
            version: 0,
            phone: "",
            windowDays: 0,
            description: "",
            updatedAt: 0,
            status: SeasonalGoalDraftStatus.proposed
        )
    }
}
