import AcmePlatform
import Foundation

extension Labs {
    /// Where a primary panel schedule is in its life cycle.
    enum PrimaryPanelScheduleStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A primary panel schedule as the panel team keeps it.
    final class PrimaryPanelSchedule {
        var code: String
        var name: String
        var source: String
        var visible: Bool
        var endsAt: Int
        var label: String
        var rate: Double
        var archived: Bool
        var status: PrimaryPanelScheduleStatus

        init(code: String, name: String, source: String, visible: Bool, endsAt: Int, label: String, rate: Double, archived: Bool, status: PrimaryPanelScheduleStatus) {
            self.code = code
            self.name = name
            self.source = source
            self.visible = visible
            self.endsAt = endsAt
            self.label = label
            self.rate = rate
            self.archived = archived
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

        func canMoveTo(_ next: PrimaryPanelScheduleStatus) -> Bool {
            switch status {
            case .idle:
                return next == PrimaryPanelScheduleStatus.stopped
            case .warming:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == PrimaryPanelScheduleStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryPanelScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary panel schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(name)"
        }

        func netTotal() -> Double {
            return ((Double(endsAt) + rate) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryPanelSchedule {
            return PrimaryPanelSchedule(
                code: code,
                name: name,
                source: source,
                visible: visible,
                endsAt: endsAt,
                label: label,
                rate: rate,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a primary panel schedule in status idle.
    static func newPrimaryPanelSchedule(_ code: String, name: String) -> PrimaryPanelSchedule {
        return PrimaryPanelSchedule(
            code: code,
            name: name,
            source: "",
            visible: false,
            endsAt: 0,
            label: "",
            rate: 0.0,
            archived: false,
            status: PrimaryPanelScheduleStatus.idle
        )
    }
}
