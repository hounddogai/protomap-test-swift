import AcmePlatform
import Foundation

extension Staffing {
    /// Where a strict overtime manifest is in its life cycle.
    enum StrictOvertimeManifestStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a strict overtime manifest and its current status.
    final class StrictOvertimeManifest {
        var code: String
        var name: String
        var encounterID: String
        var timezone: String
        var procedureCode: String
        var score: Double
        var status: StrictOvertimeManifestStatus

        init(code: String, name: String, encounterID: String, timezone: String, procedureCode: String, score: Double, status: StrictOvertimeManifestStatus) {
            self.code = code
            self.name = name
            self.encounterID = encounterID
            self.timezone = timezone
            self.procedureCode = procedureCode
            self.score = score
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

        func canMoveTo(_ next: StrictOvertimeManifestStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
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
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: StrictOvertimeManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict overtime manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> StrictOvertimeManifest {
            return StrictOvertimeManifest(
                code: code,
                name: name,
                encounterID: encounterID,
                timezone: timezone,
                procedureCode: procedureCode,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a strict overtime manifest in status idle.
    static func newStrictOvertimeManifest(_ code: String, name: String) -> StrictOvertimeManifest {
        return StrictOvertimeManifest(
            code: code,
            name: name,
            encounterID: "",
            timezone: "",
            procedureCode: "",
            score: 0.0,
            status: StrictOvertimeManifestStatus.idle
        )
    }
}
