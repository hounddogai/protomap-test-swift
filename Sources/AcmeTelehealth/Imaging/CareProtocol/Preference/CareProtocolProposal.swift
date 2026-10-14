import AcmePlatform
import Foundation

extension Imaging {
    /// Where a care protocol proposal is in its life cycle.
    enum CareProtocolProposalStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a care protocol proposal and its current status.
    final class CareProtocolProposal {
        var code: String
        var name: String
        var contactEmail: String
        var allergy: String
        var durationMinutes: Int
        var encounterID: String
        var priority: Int
        var status: CareProtocolProposalStatus

        init(code: String, name: String, contactEmail: String, allergy: String, durationMinutes: Int, encounterID: String, priority: Int, status: CareProtocolProposalStatus) {
            self.code = code
            self.name = name
            self.contactEmail = contactEmail
            self.allergy = allergy
            self.durationMinutes = durationMinutes
            self.encounterID = encounterID
            self.priority = priority
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CareProtocolProposalStatus) -> Bool {
            switch status {
            case .new:
                return next == CareProtocolProposalStatus.queued
            case .queued:
                return next == CareProtocolProposalStatus.done
            case .running:
                return next == CareProtocolProposalStatus.failed
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: CareProtocolProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("care protocol proposal") \(code)"
        }

        func projectedVolume() -> Double {
            return ((Double(durationMinutes) + Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolProposal {
            return CareProtocolProposal(
                code: code,
                name: name,
                contactEmail: contactEmail,
                allergy: allergy,
                durationMinutes: durationMinutes,
                encounterID: encounterID,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a care protocol proposal in status new.
    static func newCareProtocolProposal(_ code: String, name: String) -> CareProtocolProposal {
        return CareProtocolProposal(
            code: code,
            name: name,
            contactEmail: "",
            allergy: "",
            durationMinutes: 0,
            encounterID: "",
            priority: 0,
            status: CareProtocolProposalStatus.new
        )
    }
}
