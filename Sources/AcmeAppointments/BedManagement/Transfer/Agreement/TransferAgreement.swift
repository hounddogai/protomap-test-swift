import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a transfer agreement is in its life cycle.
    enum TransferAgreementStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A transfer agreement as the transfer team keeps it.
    final class TransferAgreement {
        var code: String
        var label: String
        var batchSize: Int
        var currency: String
        var tags: [String]
        var externalRef: String
        var status: TransferAgreementStatus

        init(code: String, label: String, batchSize: Int, currency: String, tags: [String], externalRef: String, status: TransferAgreementStatus) {
            self.code = code
            self.label = label
            self.batchSize = batchSize
            self.currency = currency
            self.tags = tags
            self.externalRef = externalRef
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TransferAgreementStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == TransferAgreementStatus.withdrawn
            case .rejected:
                return next == TransferAgreementStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TransferAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("transfer agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func measuredValue() -> Double {
            return Double(batchSize)
        }

        func copyValue() -> TransferAgreement {
            return TransferAgreement(
                code: code,
                label: label,
                batchSize: batchSize,
                currency: currency,
                tags: tags,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a transfer agreement in status proposed.
    static func newTransferAgreement(_ code: String, label: String) -> TransferAgreement {
        return TransferAgreement(
            code: code,
            label: label,
            batchSize: 0,
            currency: "",
            tags: [],
            externalRef: "",
            status: TransferAgreementStatus.proposed
        )
    }
}
