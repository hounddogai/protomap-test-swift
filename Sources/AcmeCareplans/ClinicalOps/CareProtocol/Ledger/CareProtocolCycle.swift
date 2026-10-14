import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a care protocol cycle is in its life cycle.
    enum CareProtocolCycleStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a care protocol cycle and its current status.
    final class CareProtocolCycle {
        var code: String
        var name: String
        var facility: String
        var region: String
        var summary: String
        var clinicianID: String
        var score: Double
        var status: CareProtocolCycleStatus

        init(code: String, name: String, facility: String, region: String, summary: String, clinicianID: String, score: Double, status: CareProtocolCycleStatus) {
            self.code = code
            self.name = name
            self.facility = facility
            self.region = region
            self.summary = summary
            self.clinicianID = clinicianID
            self.score = score
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

        func canMoveTo(_ next: CareProtocolCycleStatus) -> Bool {
            switch status {
            case .draft:
                return next == CareProtocolCycleStatus.closed
            case .pending:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == CareProtocolCycleStatus.closed
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

        func moveTo(_ next: CareProtocolCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> CareProtocolCycle {
            return CareProtocolCycle(
                code: code,
                name: name,
                facility: facility,
                region: region,
                summary: summary,
                clinicianID: clinicianID,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a care protocol cycle in status draft.
    static func newCareProtocolCycle(_ code: String, name: String) -> CareProtocolCycle {
        return CareProtocolCycle(
            code: code,
            name: name,
            facility: "",
            region: "",
            summary: "",
            clinicianID: "",
            score: 0.0,
            status: CareProtocolCycleStatus.draft
        )
    }
}
