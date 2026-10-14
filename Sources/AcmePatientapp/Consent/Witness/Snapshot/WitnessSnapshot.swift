import AcmePlatform
import Foundation

extension Consent {
    /// Where a witness snapshot is in its life cycle.
    enum WitnessSnapshotStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One witness snapshot, with what the planners need to act on it.
    final class WitnessSnapshot {
        var code: String
        var title: String
        var ratio: Double
        var visitMinutes: Int
        var facility: String
        var status: WitnessSnapshotStatus

        init(code: String, title: String, ratio: Double, visitMinutes: Int, facility: String, status: WitnessSnapshotStatus) {
            self.code = code
            self.title = title
            self.ratio = ratio
            self.visitMinutes = visitMinutes
            self.facility = facility
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

        func canMoveTo(_ next: WitnessSnapshotStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: WitnessSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("witness snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func projectedTotal() -> Double {
            return (ratio * Double(visitMinutes) * 100).rounded() / 100
        }

        func copyValue() -> WitnessSnapshot {
            return WitnessSnapshot(
                code: code,
                title: title,
                ratio: ratio,
                visitMinutes: visitMinutes,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a witness snapshot in status idle.
    static func newWitnessSnapshot(_ code: String, title: String) -> WitnessSnapshot {
        return WitnessSnapshot(
            code: code,
            title: title,
            ratio: 0.0,
            visitMinutes: 0,
            facility: "",
            status: WitnessSnapshotStatus.idle
        )
    }
}
