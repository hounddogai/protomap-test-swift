import AcmePlatform
import Foundation

extension Referrals {
    /// Where a follow up manifest is in its life cycle.
    enum FollowUpManifestStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One follow up manifest, with what the planners need to act on it.
    final class FollowUpManifest {
        var code: String
        var title: String
        var locale: String
        var specialty: String
        var externalRef: String
        var cost: Double
        var segment: String
        var approved: Bool
        var status: FollowUpManifestStatus

        init(code: String, title: String, locale: String, specialty: String, externalRef: String, cost: Double, segment: String, approved: Bool, status: FollowUpManifestStatus) {
            self.code = code
            self.title = title
            self.locale = locale
            self.specialty = specialty
            self.externalRef = externalRef
            self.cost = cost
            self.segment = segment
            self.approved = approved
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

        func canMoveTo(_ next: FollowUpManifestStatus) -> Bool {
            switch status {
            case .created:
                return next == FollowUpManifestStatus.published || next == FollowUpManifestStatus.retired
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == FollowUpManifestStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FollowUpManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("follow up manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func measuredValue() -> Double {
            return cost
        }

        func copyValue() -> FollowUpManifest {
            return FollowUpManifest(
                code: code,
                title: title,
                locale: locale,
                specialty: specialty,
                externalRef: externalRef,
                cost: cost,
                segment: segment,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a follow up manifest in status created.
    static func newFollowUpManifest(_ code: String, title: String) -> FollowUpManifest {
        return FollowUpManifest(
            code: code,
            title: title,
            locale: "",
            specialty: "",
            externalRef: "",
            cost: 0.0,
            segment: "",
            approved: false,
            status: FollowUpManifestStatus.created
        )
    }
}
