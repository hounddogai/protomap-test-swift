import AcmePlatform
import Foundation

extension Staffing {
    /// Where a global shift profile is in its life cycle.
    enum GlobalShiftProfileStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a global shift profile and its current status.
    final class GlobalShiftProfile {
        var code: String
        var name: String
        var score: Double
        var copay: Double
        var encounterID: String
        var weight: Double
        var startsAt: Int
        var facility: String
        var status: GlobalShiftProfileStatus

        init(code: String, name: String, score: Double, copay: Double, encounterID: String, weight: Double, startsAt: Int, facility: String, status: GlobalShiftProfileStatus) {
            self.code = code
            self.name = name
            self.score = score
            self.copay = copay
            self.encounterID = encounterID
            self.weight = weight
            self.startsAt = startsAt
            self.facility = facility
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: GlobalShiftProfileStatus) -> Bool {
            switch status {
            case .draft:
                return next == GlobalShiftProfileStatus.suspended
            case .pending:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == GlobalShiftProfileStatus.suspended || next == GlobalShiftProfileStatus.closed
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: GlobalShiftProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global shift profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("global shift profile") \(code)"
        }

        func projectedExposure() -> Double {
            return (weight * score * 100).rounded() / 100
        }

        func copyValue() -> GlobalShiftProfile {
            return GlobalShiftProfile(
                code: code,
                name: name,
                score: score,
                copay: copay,
                encounterID: encounterID,
                weight: weight,
                startsAt: startsAt,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a global shift profile in status draft.
    static func newGlobalShiftProfile(_ code: String, name: String) -> GlobalShiftProfile {
        return GlobalShiftProfile(
            code: code,
            name: name,
            score: 0.0,
            copay: 0.0,
            encounterID: "",
            weight: 0.0,
            startsAt: 0,
            facility: "",
            status: GlobalShiftProfileStatus.draft
        )
    }
}
