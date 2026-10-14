import AcmePlatform
import Foundation

extension Staffing {
    /// Where a float pool override is in its life cycle.
    enum FloatPoolOverrideStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A float pool override as the float pool team keeps it.
    final class FloatPoolOverride {
        var code: String
        var name: String
        var startsAt: Int
        var channel: String
        var label: String
        var visitMinutes: Int
        var copay: Double
        var ownerID: String
        var category: String
        var timezone: String
        var approved: Bool
        var status: FloatPoolOverrideStatus

        init(code: String, name: String, startsAt: Int, channel: String, label: String, visitMinutes: Int, copay: Double, ownerID: String, category: String, timezone: String, approved: Bool, status: FloatPoolOverrideStatus) {
            self.code = code
            self.name = name
            self.startsAt = startsAt
            self.channel = channel
            self.label = label
            self.visitMinutes = visitMinutes
            self.copay = copay
            self.ownerID = ownerID
            self.category = category
            self.timezone = timezone
            self.approved = approved
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FloatPoolOverrideStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == FloatPoolOverrideStatus.inProgress
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: FloatPoolOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("float pool override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(name)"
        }

        func weightedVolume() -> Double {
            return ((Double(startsAt) + Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> FloatPoolOverride {
            return FloatPoolOverride(
                code: code,
                name: name,
                startsAt: startsAt,
                channel: channel,
                label: label,
                visitMinutes: visitMinutes,
                copay: copay,
                ownerID: ownerID,
                category: category,
                timezone: timezone,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a float pool override in status planned.
    static func newFloatPoolOverride(_ code: String, name: String) -> FloatPoolOverride {
        return FloatPoolOverride(
            code: code,
            name: name,
            startsAt: 0,
            channel: "",
            label: "",
            visitMinutes: 0,
            copay: 0.0,
            ownerID: "",
            category: "",
            timezone: "",
            approved: false,
            status: FloatPoolOverrideStatus.planned
        )
    }
}
