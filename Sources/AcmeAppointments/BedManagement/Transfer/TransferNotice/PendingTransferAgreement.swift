import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a pending transfer agreement is in its life cycle.
    enum PendingTransferAgreementStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One pending transfer agreement, with what the planners need to act on it.
    final class PendingTransferAgreement {
        var code: String
        var name: String
        var sequence: Int
        var country: String
        var ceiling: Double
        var timezone: String
        var encounterID: String
        var channel: String
        var attempts: Int
        var budget: Double
        var floorValue: Double
        var status: PendingTransferAgreementStatus

        init(code: String, name: String, sequence: Int, country: String, ceiling: Double, timezone: String, encounterID: String, channel: String, attempts: Int, budget: Double, floorValue: Double, status: PendingTransferAgreementStatus) {
            self.code = code
            self.name = name
            self.sequence = sequence
            self.country = country
            self.ceiling = ceiling
            self.timezone = timezone
            self.encounterID = encounterID
            self.channel = channel
            self.attempts = attempts
            self.budget = budget
            self.floorValue = floorValue
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

        func canMoveTo(_ next: PendingTransferAgreementStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == PendingTransferAgreementStatus.active || next == PendingTransferAgreementStatus.closed
            case .active:
                return next == PendingTransferAgreementStatus.suspended || next == PendingTransferAgreementStatus.closed
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

        func moveTo(_ next: PendingTransferAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending transfer agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func weightedTotal() -> Double {
            return ((floorValue - budget) * 100).rounded() / 100
        }

        func copyValue() -> PendingTransferAgreement {
            return PendingTransferAgreement(
                code: code,
                name: name,
                sequence: sequence,
                country: country,
                ceiling: ceiling,
                timezone: timezone,
                encounterID: encounterID,
                channel: channel,
                attempts: attempts,
                budget: budget,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a pending transfer agreement in status draft.
    static func newPendingTransferAgreement(_ code: String, name: String) -> PendingTransferAgreement {
        return PendingTransferAgreement(
            code: code,
            name: name,
            sequence: 0,
            country: "",
            ceiling: 0.0,
            timezone: "",
            encounterID: "",
            channel: "",
            attempts: 0,
            budget: 0.0,
            floorValue: 0.0,
            status: PendingTransferAgreementStatus.draft
        )
    }
}
