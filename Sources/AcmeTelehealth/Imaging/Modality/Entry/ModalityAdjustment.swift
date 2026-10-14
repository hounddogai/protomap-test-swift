import AcmePlatform
import Foundation

extension Imaging {
    /// Where a modality adjustment is in its life cycle.
    enum ModalityAdjustmentStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A modality adjustment as the modality team keeps it.
    final class ModalityAdjustment {
        var code: String
        var label: String
        var bed: String
        var approved: Bool
        var segment: String
        var startsAt: Int
        var currency: String
        var amount: Double
        var channel: String
        var retries: Int
        var ceiling: Double
        var status: ModalityAdjustmentStatus

        init(code: String, label: String, bed: String, approved: Bool, segment: String, startsAt: Int, currency: String, amount: Double, channel: String, retries: Int, ceiling: Double, status: ModalityAdjustmentStatus) {
            self.code = code
            self.label = label
            self.bed = bed
            self.approved = approved
            self.segment = segment
            self.startsAt = startsAt
            self.currency = currency
            self.amount = amount
            self.channel = channel
            self.retries = retries
            self.ceiling = ceiling
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

        func canMoveTo(_ next: ModalityAdjustmentStatus) -> Bool {
            switch status {
            case .created:
                return next == ModalityAdjustmentStatus.published
            case .validated:
                return next == ModalityAdjustmentStatus.published || next == ModalityAdjustmentStatus.retired
            case .published:
                return next == ModalityAdjustmentStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ModalityAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("modality adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("modality adjustment") \(code)"
        }

        func adjustedExposure() -> Double {
            return (Double(retries) * Double(startsAt) * 100).rounded() / 100
        }

        func copyValue() -> ModalityAdjustment {
            return ModalityAdjustment(
                code: code,
                label: label,
                bed: bed,
                approved: approved,
                segment: segment,
                startsAt: startsAt,
                currency: currency,
                amount: amount,
                channel: channel,
                retries: retries,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a modality adjustment in status created.
    static func newModalityAdjustment(_ code: String, label: String) -> ModalityAdjustment {
        return ModalityAdjustment(
            code: code,
            label: label,
            bed: "",
            approved: false,
            segment: "",
            startsAt: 0,
            currency: "",
            amount: 0.0,
            channel: "",
            retries: 0,
            ceiling: 0.0,
            status: ModalityAdjustmentStatus.created
        )
    }
}
