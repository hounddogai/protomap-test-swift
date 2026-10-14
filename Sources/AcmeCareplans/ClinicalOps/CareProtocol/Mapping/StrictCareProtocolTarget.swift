import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a strict care protocol target is in its life cycle.
    enum StrictCareProtocolTargetStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One strict care protocol target, with what the planners need to act on it.
    final class StrictCareProtocolTarget {
        var code: String
        var label: String
        var archived: Bool
        var durationMinutes: Int
        var createdAt: Int
        var procedureCode: String
        var specialty: String
        var status: StrictCareProtocolTargetStatus

        init(code: String, label: String, archived: Bool, durationMinutes: Int, createdAt: Int, procedureCode: String, specialty: String, status: StrictCareProtocolTargetStatus) {
            self.code = code
            self.label = label
            self.archived = archived
            self.durationMinutes = durationMinutes
            self.createdAt = createdAt
            self.procedureCode = procedureCode
            self.specialty = specialty
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

        func canMoveTo(_ next: StrictCareProtocolTargetStatus) -> Bool {
            switch status {
            case .idle:
                return next == StrictCareProtocolTargetStatus.draining || next == StrictCareProtocolTargetStatus.stopped
            case .warming:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == StrictCareProtocolTargetStatus.draining || next == StrictCareProtocolTargetStatus.stopped
            case .draining:
                return next == StrictCareProtocolTargetStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictCareProtocolTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict care protocol target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func projectedValue() -> Double {
            return ((Double(durationMinutes) + Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> StrictCareProtocolTarget {
            return StrictCareProtocolTarget(
                code: code,
                label: label,
                archived: archived,
                durationMinutes: durationMinutes,
                createdAt: createdAt,
                procedureCode: procedureCode,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a strict care protocol target in status idle.
    static func newStrictCareProtocolTarget(_ code: String, label: String) -> StrictCareProtocolTarget {
        return StrictCareProtocolTarget(
            code: code,
            label: label,
            archived: false,
            durationMinutes: 0,
            createdAt: 0,
            procedureCode: "",
            specialty: "",
            status: StrictCareProtocolTargetStatus.idle
        )
    }
}
