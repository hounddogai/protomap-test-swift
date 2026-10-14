import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a regional order set group is in its life cycle.
    enum RegionalOrderSetGroupStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One regional order set group, with what the planners need to act on it.
    final class RegionalOrderSetGroup {
        var code: String
        var name: String
        var ceiling: Double
        var notes: String
        var patientRef: String
        var capacity: Int
        var score: Double
        var weight: Double
        var attempts: Int
        var approved: Bool
        var status: RegionalOrderSetGroupStatus

        init(code: String, name: String, ceiling: Double, notes: String, patientRef: String, capacity: Int, score: Double, weight: Double, attempts: Int, approved: Bool, status: RegionalOrderSetGroupStatus) {
            self.code = code
            self.name = name
            self.ceiling = ceiling
            self.notes = notes
            self.patientRef = patientRef
            self.capacity = capacity
            self.score = score
            self.weight = weight
            self.attempts = attempts
            self.approved = approved
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

        func canMoveTo(_ next: RegionalOrderSetGroupStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == RegionalOrderSetGroupStatus.draining || next == RegionalOrderSetGroupStatus.stopped
            case .ready:
                return next == RegionalOrderSetGroupStatus.draining || next == RegionalOrderSetGroupStatus.stopped
            case .draining:
                return next == RegionalOrderSetGroupStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalOrderSetGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional order set group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func projectedValue() -> Double {
            return ((score - Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> RegionalOrderSetGroup {
            return RegionalOrderSetGroup(
                code: code,
                name: name,
                ceiling: ceiling,
                notes: notes,
                patientRef: patientRef,
                capacity: capacity,
                score: score,
                weight: weight,
                attempts: attempts,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a regional order set group in status idle.
    static func newRegionalOrderSetGroup(_ code: String, name: String) -> RegionalOrderSetGroup {
        return RegionalOrderSetGroup(
            code: code,
            name: name,
            ceiling: 0.0,
            notes: "",
            patientRef: "",
            capacity: 0,
            score: 0.0,
            weight: 0.0,
            attempts: 0,
            approved: false,
            status: RegionalOrderSetGroupStatus.idle
        )
    }
}
