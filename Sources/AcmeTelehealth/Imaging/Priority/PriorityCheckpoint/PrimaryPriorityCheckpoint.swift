import AcmePlatform
import Foundation

extension Imaging {
    /// Where a primary priority checkpoint is in its life cycle.
    enum PrimaryPriorityCheckpointStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One primary priority checkpoint, with what the planners need to act on it.
    final class PrimaryPriorityCheckpoint {
        var code: String
        var name: String
        var unit: String
        var patientRef: String
        var tags: [String]
        var bed: String
        var score: Double
        var quantity: Int
        var locale: String
        var status: PrimaryPriorityCheckpointStatus

        init(code: String, name: String, unit: String, patientRef: String, tags: [String], bed: String, score: Double, quantity: Int, locale: String, status: PrimaryPriorityCheckpointStatus) {
            self.code = code
            self.name = name
            self.unit = unit
            self.patientRef = patientRef
            self.tags = tags
            self.bed = bed
            self.score = score
            self.quantity = quantity
            self.locale = locale
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PrimaryPriorityCheckpointStatus) -> Bool {
            switch status {
            case .requested:
                return next == PrimaryPriorityCheckpointStatus.revoked
            case .granted:
                return next == PrimaryPriorityCheckpointStatus.revoked
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: PrimaryPriorityCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary priority checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("primary priority checkpoint") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedLoad() -> Double {
            return ((score - Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryPriorityCheckpoint {
            return PrimaryPriorityCheckpoint(
                code: code,
                name: name,
                unit: unit,
                patientRef: patientRef,
                tags: tags,
                bed: bed,
                score: score,
                quantity: quantity,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a primary priority checkpoint in status requested.
    static func newPrimaryPriorityCheckpoint(_ code: String, name: String) -> PrimaryPriorityCheckpoint {
        return PrimaryPriorityCheckpoint(
            code: code,
            name: name,
            unit: "",
            patientRef: "",
            tags: [],
            bed: "",
            score: 0.0,
            quantity: 0,
            locale: "",
            status: PrimaryPriorityCheckpointStatus.requested
        )
    }
}
