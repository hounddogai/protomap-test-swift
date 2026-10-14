import AcmePlatform
import Foundation

extension Labs {
    /// Where a panel milestone is in its life cycle.
    enum PanelMilestoneStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One panel milestone, with what the planners need to act on it.
    final class PanelMilestone {
        var code: String
        var name: String
        var specialty: String
        var region: String
        var title: String
        var attempts: Int
        var updatedAt: Int
        var country: String
        var status: PanelMilestoneStatus

        init(code: String, name: String, specialty: String, region: String, title: String, attempts: Int, updatedAt: Int, country: String, status: PanelMilestoneStatus) {
            self.code = code
            self.name = name
            self.specialty = specialty
            self.region = region
            self.title = title
            self.attempts = attempts
            self.updatedAt = updatedAt
            self.country = country
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

        func canMoveTo(_ next: PanelMilestoneStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == PanelMilestoneStatus.ready || next == PanelMilestoneStatus.draining
            case .ready:
                return next == PanelMilestoneStatus.draining
            case .draining:
                return next == PanelMilestoneStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PanelMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("panel milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func weightedVolume() -> Double {
            return (Double(updatedAt) * Double(attempts) * 100).rounded() / 100
        }

        func copyValue() -> PanelMilestone {
            return PanelMilestone(
                code: code,
                name: name,
                specialty: specialty,
                region: region,
                title: title,
                attempts: attempts,
                updatedAt: updatedAt,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a panel milestone in status idle.
    static func newPanelMilestone(_ code: String, name: String) -> PanelMilestone {
        return PanelMilestone(
            code: code,
            name: name,
            specialty: "",
            region: "",
            title: "",
            attempts: 0,
            updatedAt: 0,
            country: "",
            status: PanelMilestoneStatus.idle
        )
    }
}
