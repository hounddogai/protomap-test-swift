import AcmePlatform
import Foundation

extension Consent {
    /// Where a witness group is in its life cycle.
    enum WitnessGroupStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A witness group as the witness team keeps it.
    final class WitnessGroup {
        var code: String
        var label: String
        var description: String
        var facility: String
        var tags: [String]
        var rate: Double
        var status: WitnessGroupStatus

        init(code: String, label: String, description: String, facility: String, tags: [String], rate: Double, status: WitnessGroupStatus) {
            self.code = code
            self.label = label
            self.description = description
            self.facility = facility
            self.tags = tags
            self.rate = rate
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

        func canMoveTo(_ next: WitnessGroupStatus) -> Bool {
            switch status {
            case .planned:
                return next == WitnessGroupStatus.completed
            case .scheduled:
                return next == WitnessGroupStatus.inProgress || next == WitnessGroupStatus.completed
            case .inProgress:
                return next == WitnessGroupStatus.completed
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

        func moveTo(_ next: WitnessGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("witness group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func measuredValue() -> Double {
            return rate
        }

        func copyValue() -> WitnessGroup {
            return WitnessGroup(
                code: code,
                label: label,
                description: description,
                facility: facility,
                tags: tags,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a witness group in status planned.
    static func newWitnessGroup(_ code: String, label: String) -> WitnessGroup {
        return WitnessGroup(
            code: code,
            label: label,
            description: "",
            facility: "",
            tags: [],
            rate: 0.0,
            status: WitnessGroupStatus.planned
        )
    }
}
