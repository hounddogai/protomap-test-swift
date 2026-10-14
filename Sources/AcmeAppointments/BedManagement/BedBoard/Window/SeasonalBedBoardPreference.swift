import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a seasonal bed board preference is in its life cycle.
    enum SeasonalBedBoardPreferenceStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A seasonal bed board preference. Its code is unique within a tenant.
    final class SeasonalBedBoardPreference {
        var code: String
        var title: String
        var discount: Double
        var updatedAt: Int
        var priority: Int
        var label: String
        var revision: Int
        var tags: [String]
        var status: SeasonalBedBoardPreferenceStatus

        init(code: String, title: String, discount: Double, updatedAt: Int, priority: Int, label: String, revision: Int, tags: [String], status: SeasonalBedBoardPreferenceStatus) {
            self.code = code
            self.title = title
            self.discount = discount
            self.updatedAt = updatedAt
            self.priority = priority
            self.label = label
            self.revision = revision
            self.tags = tags
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

        func canMoveTo(_ next: SeasonalBedBoardPreferenceStatus) -> Bool {
            switch status {
            case .requested:
                return next == SeasonalBedBoardPreferenceStatus.granted || next == SeasonalBedBoardPreferenceStatus.expired
            case .granted:
                return next == SeasonalBedBoardPreferenceStatus.revoked || next == SeasonalBedBoardPreferenceStatus.expired
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

        func moveTo(_ next: SeasonalBedBoardPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal bed board preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) (\(title))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveLoad() -> Double {
            return ((Double(updatedAt) + Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalBedBoardPreference {
            return SeasonalBedBoardPreference(
                code: code,
                title: title,
                discount: discount,
                updatedAt: updatedAt,
                priority: priority,
                label: label,
                revision: revision,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a seasonal bed board preference in status requested.
    static func newSeasonalBedBoardPreference(_ code: String, title: String) -> SeasonalBedBoardPreference {
        return SeasonalBedBoardPreference(
            code: code,
            title: title,
            discount: 0.0,
            updatedAt: 0,
            priority: 0,
            label: "",
            revision: 0,
            tags: [],
            status: SeasonalBedBoardPreferenceStatus.requested
        )
    }
}
