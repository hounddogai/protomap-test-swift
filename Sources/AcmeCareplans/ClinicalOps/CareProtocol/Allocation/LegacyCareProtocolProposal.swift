import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a legacy care protocol proposal is in its life cycle.
    enum LegacyCareProtocolProposalStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A legacy care protocol proposal as the care protocol team keeps it.
    final class LegacyCareProtocolProposal {
        var code: String
        var name: String
        var visitMinutes: Int
        var notes: String
        var patientRef: String
        var attributes: [String: String]
        var timezone: String
        var startsAt: Int
        var procedureCode: String
        var capacity: Int
        var status: LegacyCareProtocolProposalStatus

        init(code: String, name: String, visitMinutes: Int, notes: String, patientRef: String, attributes: [String: String], timezone: String, startsAt: Int, procedureCode: String, capacity: Int, status: LegacyCareProtocolProposalStatus) {
            self.code = code
            self.name = name
            self.visitMinutes = visitMinutes
            self.notes = notes
            self.patientRef = patientRef
            self.attributes = attributes
            self.timezone = timezone
            self.startsAt = startsAt
            self.procedureCode = procedureCode
            self.capacity = capacity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LegacyCareProtocolProposalStatus) -> Bool {
            switch status {
            case .planned:
                return next == LegacyCareProtocolProposalStatus.scheduled
            case .scheduled:
                return next == LegacyCareProtocolProposalStatus.inProgress || next == LegacyCareProtocolProposalStatus.completed
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == LegacyCareProtocolProposalStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyCareProtocolProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy care protocol proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
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

        func adjustedLoad() -> Double {
            return (Double(startsAt) * Double(capacity) * 100).rounded() / 100
        }

        func copyValue() -> LegacyCareProtocolProposal {
            return LegacyCareProtocolProposal(
                code: code,
                name: name,
                visitMinutes: visitMinutes,
                notes: notes,
                patientRef: patientRef,
                attributes: attributes,
                timezone: timezone,
                startsAt: startsAt,
                procedureCode: procedureCode,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a legacy care protocol proposal in status planned.
    static func newLegacyCareProtocolProposal(_ code: String, name: String) -> LegacyCareProtocolProposal {
        return LegacyCareProtocolProposal(
            code: code,
            name: name,
            visitMinutes: 0,
            notes: "",
            patientRef: "",
            attributes: [:],
            timezone: "",
            startsAt: 0,
            procedureCode: "",
            capacity: 0,
            status: LegacyCareProtocolProposalStatus.planned
        )
    }
}
