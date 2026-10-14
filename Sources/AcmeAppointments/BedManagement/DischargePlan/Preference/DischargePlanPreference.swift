import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a discharge plan preference is in its life cycle.
    enum DischargePlanPreferenceStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One discharge plan preference, with what the planners need to act on it.
    final class DischargePlanPreference {
        var code: String
        var name: String
        var sequence: Int
        var title: String
        var discount: Double
        var status: DischargePlanPreferenceStatus

        init(code: String, name: String, sequence: Int, title: String, discount: Double, status: DischargePlanPreferenceStatus) {
            self.code = code
            self.name = name
            self.sequence = sequence
            self.title = title
            self.discount = discount
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

        func canMoveTo(_ next: DischargePlanPreferenceStatus) -> Bool {
            switch status {
            case .idle:
                return next == DischargePlanPreferenceStatus.ready || next == DischargePlanPreferenceStatus.draining
            case .warming:
                return next == DischargePlanPreferenceStatus.draining
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == DischargePlanPreferenceStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DischargePlanPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("discharge plan preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func projectedTotal() -> Double {
            return (discount * Double(sequence) * 100).rounded() / 100
        }

        func copyValue() -> DischargePlanPreference {
            return DischargePlanPreference(
                code: code,
                name: name,
                sequence: sequence,
                title: title,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a discharge plan preference in status idle.
    static func newDischargePlanPreference(_ code: String, name: String) -> DischargePlanPreference {
        return DischargePlanPreference(
            code: code,
            name: name,
            sequence: 0,
            title: "",
            discount: 0.0,
            status: DischargePlanPreferenceStatus.idle
        )
    }
}
