import AcmePlatform
import Foundation

extension Imaging {
    /// Where a modality threshold is in its life cycle.
    enum ModalityThresholdStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A modality threshold as the modality team keeps it.
    final class ModalityThreshold {
        var code: String
        var title: String
        var graceDays: Int
        var amount: Double
        var allergy: String
        var visitMinutes: Int
        var summary: String
        var endsAt: Int
        var quantity: Int
        var minimum: Double
        var status: ModalityThresholdStatus

        init(code: String, title: String, graceDays: Int, amount: Double, allergy: String, visitMinutes: Int, summary: String, endsAt: Int, quantity: Int, minimum: Double, status: ModalityThresholdStatus) {
            self.code = code
            self.title = title
            self.graceDays = graceDays
            self.amount = amount
            self.allergy = allergy
            self.visitMinutes = visitMinutes
            self.summary = summary
            self.endsAt = endsAt
            self.quantity = quantity
            self.minimum = minimum
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

        func canMoveTo(_ next: ModalityThresholdStatus) -> Bool {
            switch status {
            case .planned:
                return next == ModalityThresholdStatus.completed
            case .scheduled:
                return next == ModalityThresholdStatus.inProgress
            case .inProgress:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == ModalityThresholdStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ModalityThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("modality threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func adjustedVolume() -> Double {
            return ((Double(graceDays) + Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> ModalityThreshold {
            return ModalityThreshold(
                code: code,
                title: title,
                graceDays: graceDays,
                amount: amount,
                allergy: allergy,
                visitMinutes: visitMinutes,
                summary: summary,
                endsAt: endsAt,
                quantity: quantity,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a modality threshold in status planned.
    static func newModalityThreshold(_ code: String, title: String) -> ModalityThreshold {
        return ModalityThreshold(
            code: code,
            title: title,
            graceDays: 0,
            amount: 0.0,
            allergy: "",
            visitMinutes: 0,
            summary: "",
            endsAt: 0,
            quantity: 0,
            minimum: 0.0,
            status: ModalityThresholdStatus.planned
        )
    }
}
