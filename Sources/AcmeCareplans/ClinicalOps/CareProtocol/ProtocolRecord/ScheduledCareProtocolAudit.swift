import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a scheduled care protocol audit is in its life cycle.
    enum ScheduledCareProtocolAuditStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A scheduled care protocol audit. Its code is unique within a tenant.
    final class ScheduledCareProtocolAudit {
        var code: String
        var label: String
        var score: Double
        var archived: Bool
        var clinicianID: String
        var channel: String
        var payer: String
        var notes: String
        var externalRef: String
        var status: ScheduledCareProtocolAuditStatus

        init(code: String, label: String, score: Double, archived: Bool, clinicianID: String, channel: String, payer: String, notes: String, externalRef: String, status: ScheduledCareProtocolAuditStatus) {
            self.code = code
            self.label = label
            self.score = score
            self.archived = archived
            self.clinicianID = clinicianID
            self.channel = channel
            self.payer = payer
            self.notes = notes
            self.externalRef = externalRef
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

        func canMoveTo(_ next: ScheduledCareProtocolAuditStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == ScheduledCareProtocolAuditStatus.draining || next == ScheduledCareProtocolAuditStatus.stopped
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == ScheduledCareProtocolAuditStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledCareProtocolAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled care protocol audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> ScheduledCareProtocolAudit {
            return ScheduledCareProtocolAudit(
                code: code,
                label: label,
                score: score,
                archived: archived,
                clinicianID: clinicianID,
                channel: channel,
                payer: payer,
                notes: notes,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a scheduled care protocol audit in status idle.
    static func newScheduledCareProtocolAudit(_ code: String, label: String) -> ScheduledCareProtocolAudit {
        return ScheduledCareProtocolAudit(
            code: code,
            label: label,
            score: 0.0,
            archived: false,
            clinicianID: "",
            channel: "",
            payer: "",
            notes: "",
            externalRef: "",
            status: ScheduledCareProtocolAuditStatus.idle
        )
    }
}
