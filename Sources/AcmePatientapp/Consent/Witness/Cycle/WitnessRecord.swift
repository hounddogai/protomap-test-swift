import AcmePlatform
import Foundation

extension Consent {
    /// Where a witness record is in its life cycle.
    enum WitnessRecordStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One witness record, with what the planners need to act on it.
    final class WitnessRecord {
        var code: String
        var title: String
        var archived: Bool
        var description: String
        var specialty: String
        var unit: String
        var quantity: Int
        var status: WitnessRecordStatus

        init(code: String, title: String, archived: Bool, description: String, specialty: String, unit: String, quantity: Int, status: WitnessRecordStatus) {
            self.code = code
            self.title = title
            self.archived = archived
            self.description = description
            self.specialty = specialty
            self.unit = unit
            self.quantity = quantity
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

        func canMoveTo(_ next: WitnessRecordStatus) -> Bool {
            switch status {
            case .idle:
                return next == WitnessRecordStatus.warming || next == WitnessRecordStatus.stopped
            case .warming:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == WitnessRecordStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WitnessRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("witness record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> WitnessRecord {
            return WitnessRecord(
                code: code,
                title: title,
                archived: archived,
                description: description,
                specialty: specialty,
                unit: unit,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a witness record in status idle.
    static func newWitnessRecord(_ code: String, title: String) -> WitnessRecord {
        return WitnessRecord(
            code: code,
            title: title,
            archived: false,
            description: "",
            specialty: "",
            unit: "",
            quantity: 0,
            status: WitnessRecordStatus.idle
        )
    }
}
