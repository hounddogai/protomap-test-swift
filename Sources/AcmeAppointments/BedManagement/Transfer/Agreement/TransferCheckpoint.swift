import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a transfer checkpoint is in its life cycle.
    enum TransferCheckpointStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One transfer checkpoint, with what the planners need to act on it.
    final class TransferCheckpoint {
        var code: String
        var title: String
        var phone: String
        var externalRef: String
        var ceiling: Double
        var amount: Double
        var segment: String
        var tags: [String]
        var label: String
        var discount: Double
        var status: TransferCheckpointStatus

        init(code: String, title: String, phone: String, externalRef: String, ceiling: Double, amount: Double, segment: String, tags: [String], label: String, discount: Double, status: TransferCheckpointStatus) {
            self.code = code
            self.title = title
            self.phone = phone
            self.externalRef = externalRef
            self.ceiling = ceiling
            self.amount = amount
            self.segment = segment
            self.tags = tags
            self.label = label
            self.discount = discount
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TransferCheckpointStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == TransferCheckpointStatus.published || next == TransferCheckpointStatus.retired
            case .published:
                return next == TransferCheckpointStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TransferCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("transfer checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(title))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedExposure() -> Double {
            return (discount * amount * 100).rounded() / 100
        }

        func copyValue() -> TransferCheckpoint {
            return TransferCheckpoint(
                code: code,
                title: title,
                phone: phone,
                externalRef: externalRef,
                ceiling: ceiling,
                amount: amount,
                segment: segment,
                tags: tags,
                label: label,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a transfer checkpoint in status created.
    static func newTransferCheckpoint(_ code: String, title: String) -> TransferCheckpoint {
        return TransferCheckpoint(
            code: code,
            title: title,
            phone: "",
            externalRef: "",
            ceiling: 0.0,
            amount: 0.0,
            segment: "",
            tags: [],
            label: "",
            discount: 0.0,
            status: TransferCheckpointStatus.created
        )
    }
}
