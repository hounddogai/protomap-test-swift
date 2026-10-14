import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a seasonal isolation profile is in its life cycle.
    enum SeasonalIsolationProfileStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a seasonal isolation profile and its current status.
    final class SeasonalIsolationProfile {
        var code: String
        var label: String
        var specialty: String
        var title: String
        var clinicianID: String
        var active: Bool
        var name: String
        var approved: Bool
        var ceiling: Double
        var status: SeasonalIsolationProfileStatus

        init(code: String, label: String, specialty: String, title: String, clinicianID: String, active: Bool, name: String, approved: Bool, ceiling: Double, status: SeasonalIsolationProfileStatus) {
            self.code = code
            self.label = label
            self.specialty = specialty
            self.title = title
            self.clinicianID = clinicianID
            self.active = active
            self.name = name
            self.approved = approved
            self.ceiling = ceiling
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

        func canMoveTo(_ next: SeasonalIsolationProfileStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .resolved:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == SeasonalIsolationProfileStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalIsolationProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal isolation profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func measuredValue() -> Double {
            return ceiling
        }

        func copyValue() -> SeasonalIsolationProfile {
            return SeasonalIsolationProfile(
                code: code,
                label: label,
                specialty: specialty,
                title: title,
                clinicianID: clinicianID,
                active: active,
                name: name,
                approved: approved,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a seasonal isolation profile in status open.
    static func newSeasonalIsolationProfile(_ code: String, label: String) -> SeasonalIsolationProfile {
        return SeasonalIsolationProfile(
            code: code,
            label: label,
            specialty: "",
            title: "",
            clinicianID: "",
            active: false,
            name: "",
            approved: false,
            ceiling: 0.0,
            status: SeasonalIsolationProfileStatus.`open`
        )
    }
}
