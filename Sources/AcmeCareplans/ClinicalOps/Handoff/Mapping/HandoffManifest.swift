import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a handoff manifest is in its life cycle.
    enum HandoffManifestStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A handoff manifest as the handoff team keeps it.
    final class HandoffManifest {
        var code: String
        var name: String
        var reviewer: String
        var minimum: Double
        var sequence: Int
        var unit: String
        var status: HandoffManifestStatus

        init(code: String, name: String, reviewer: String, minimum: Double, sequence: Int, unit: String, status: HandoffManifestStatus) {
            self.code = code
            self.name = name
            self.reviewer = reviewer
            self.minimum = minimum
            self.sequence = sequence
            self.unit = unit
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

        func canMoveTo(_ next: HandoffManifestStatus) -> Bool {
            switch status {
            case .created:
                return next == HandoffManifestStatus.validated || next == HandoffManifestStatus.retired
            case .validated:
                return next == HandoffManifestStatus.published
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: HandoffManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("handoff manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func weightedValue() -> Double {
            return ((Double(sequence) + minimum) * 100).rounded() / 100
        }

        func copyValue() -> HandoffManifest {
            return HandoffManifest(
                code: code,
                name: name,
                reviewer: reviewer,
                minimum: minimum,
                sequence: sequence,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a handoff manifest in status created.
    static func newHandoffManifest(_ code: String, name: String) -> HandoffManifest {
        return HandoffManifest(
            code: code,
            name: name,
            reviewer: "",
            minimum: 0.0,
            sequence: 0,
            unit: "",
            status: HandoffManifestStatus.created
        )
    }
}
