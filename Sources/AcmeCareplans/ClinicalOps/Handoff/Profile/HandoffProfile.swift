import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a handoff profile is in its life cycle.
    enum HandoffProfileStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One handoff profile, with what the planners need to act on it.
    final class HandoffProfile {
        var code: String
        var label: String
        var name: String
        var procedureCode: String
        var floorValue: Double
        var score: Double
        var graceDays: Int
        var status: HandoffProfileStatus

        init(code: String, label: String, name: String, procedureCode: String, floorValue: Double, score: Double, graceDays: Int, status: HandoffProfileStatus) {
            self.code = code
            self.label = label
            self.name = name
            self.procedureCode = procedureCode
            self.floorValue = floorValue
            self.score = score
            self.graceDays = graceDays
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

        func canMoveTo(_ next: HandoffProfileStatus) -> Bool {
            switch status {
            case .created:
                return next == HandoffProfileStatus.published
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == HandoffProfileStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: HandoffProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("handoff profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func netValue() -> Double {
            return ((Double(graceDays) + floorValue) * 100).rounded() / 100
        }

        func copyValue() -> HandoffProfile {
            return HandoffProfile(
                code: code,
                label: label,
                name: name,
                procedureCode: procedureCode,
                floorValue: floorValue,
                score: score,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a handoff profile in status created.
    static func newHandoffProfile(_ code: String, label: String) -> HandoffProfile {
        return HandoffProfile(
            code: code,
            label: label,
            name: "",
            procedureCode: "",
            floorValue: 0.0,
            score: 0.0,
            graceDays: 0,
            status: HandoffProfileStatus.created
        )
    }
}
