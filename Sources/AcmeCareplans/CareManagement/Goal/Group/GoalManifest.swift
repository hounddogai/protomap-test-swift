import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a goal manifest is in its life cycle.
    enum GoalManifestStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A goal manifest. Its code is unique within a tenant.
    final class GoalManifest {
        var code: String
        var label: String
        var region: String
        var phone: String
        var country: String
        var archived: Bool
        var expiresAt: Int
        var visitMinutes: Int
        var status: GoalManifestStatus

        init(code: String, label: String, region: String, phone: String, country: String, archived: Bool, expiresAt: Int, visitMinutes: Int, status: GoalManifestStatus) {
            self.code = code
            self.label = label
            self.region = region
            self.phone = phone
            self.country = country
            self.archived = archived
            self.expiresAt = expiresAt
            self.visitMinutes = visitMinutes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: GoalManifestStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == GoalManifestStatus.ready || next == GoalManifestStatus.stopped
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: GoalManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("goal manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func netExposure() -> Double {
            return ((Double(visitMinutes) + Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> GoalManifest {
            return GoalManifest(
                code: code,
                label: label,
                region: region,
                phone: phone,
                country: country,
                archived: archived,
                expiresAt: expiresAt,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a goal manifest in status idle.
    static func newGoalManifest(_ code: String, label: String) -> GoalManifest {
        return GoalManifest(
            code: code,
            label: label,
            region: "",
            phone: "",
            country: "",
            archived: false,
            expiresAt: 0,
            visitMinutes: 0,
            status: GoalManifestStatus.idle
        )
    }
}
