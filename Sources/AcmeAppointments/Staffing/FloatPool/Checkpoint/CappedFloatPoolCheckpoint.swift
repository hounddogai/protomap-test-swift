import AcmePlatform
import Foundation

extension Staffing {
    /// Where a capped float pool checkpoint is in its life cycle.
    enum CappedFloatPoolCheckpointStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One capped float pool checkpoint, with what the planners need to act on it.
    final class CappedFloatPoolCheckpoint {
        var code: String
        var label: String
        var attributes: [String: String]
        var visitMinutes: Int
        var minimum: Double
        var status: CappedFloatPoolCheckpointStatus

        init(code: String, label: String, attributes: [String: String], visitMinutes: Int, minimum: Double, status: CappedFloatPoolCheckpointStatus) {
            self.code = code
            self.label = label
            self.attributes = attributes
            self.visitMinutes = visitMinutes
            self.minimum = minimum
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CappedFloatPoolCheckpointStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == CappedFloatPoolCheckpointStatus.rejected
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: CappedFloatPoolCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped float pool checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func weightedLoad() -> Double {
            return ((minimum - Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> CappedFloatPoolCheckpoint {
            return CappedFloatPoolCheckpoint(
                code: code,
                label: label,
                attributes: attributes,
                visitMinutes: visitMinutes,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a capped float pool checkpoint in status proposed.
    static func newCappedFloatPoolCheckpoint(_ code: String, label: String) -> CappedFloatPoolCheckpoint {
        return CappedFloatPoolCheckpoint(
            code: code,
            label: label,
            attributes: [:],
            visitMinutes: 0,
            minimum: 0.0,
            status: CappedFloatPoolCheckpointStatus.proposed
        )
    }
}
