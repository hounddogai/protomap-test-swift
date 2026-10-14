import AcmePlatform
import Foundation

extension Consent {
    /// Where a primary proxy checkpoint is in its life cycle.
    enum PrimaryProxyCheckpointStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One primary proxy checkpoint, with what the planners need to act on it.
    final class PrimaryProxyCheckpoint {
        var code: String
        var label: String
        var procedureCode: String
        var checksum: String
        var currency: String
        var description: String
        var amount: Double
        var archived: Bool
        var country: String
        var copay: Double
        var status: PrimaryProxyCheckpointStatus

        init(code: String, label: String, procedureCode: String, checksum: String, currency: String, description: String, amount: Double, archived: Bool, country: String, copay: Double, status: PrimaryProxyCheckpointStatus) {
            self.code = code
            self.label = label
            self.procedureCode = procedureCode
            self.checksum = checksum
            self.currency = currency
            self.description = description
            self.amount = amount
            self.archived = archived
            self.country = country
            self.copay = copay
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

        func canMoveTo(_ next: PrimaryProxyCheckpointStatus) -> Bool {
            switch status {
            case .idle:
                return next == PrimaryProxyCheckpointStatus.warming
            case .warming:
                return next == PrimaryProxyCheckpointStatus.draining
            case .ready:
                return next == PrimaryProxyCheckpointStatus.draining || next == PrimaryProxyCheckpointStatus.stopped
            case .draining:
                return next == PrimaryProxyCheckpointStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryProxyCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary proxy checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func weightedTotal() -> Double {
            return ((copay - amount) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryProxyCheckpoint {
            return PrimaryProxyCheckpoint(
                code: code,
                label: label,
                procedureCode: procedureCode,
                checksum: checksum,
                currency: currency,
                description: description,
                amount: amount,
                archived: archived,
                country: country,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a primary proxy checkpoint in status idle.
    static func newPrimaryProxyCheckpoint(_ code: String, label: String) -> PrimaryProxyCheckpoint {
        return PrimaryProxyCheckpoint(
            code: code,
            label: label,
            procedureCode: "",
            checksum: "",
            currency: "",
            description: "",
            amount: 0.0,
            archived: false,
            country: "",
            copay: 0.0,
            status: PrimaryProxyCheckpointStatus.idle
        )
    }
}
