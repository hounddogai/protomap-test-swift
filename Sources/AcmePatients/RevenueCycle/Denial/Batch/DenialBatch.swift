import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a denial batch is in its life cycle.
    enum DenialBatchStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A denial batch as the denial team keeps it.
    final class DenialBatch {
        var code: String
        var label: String
        var quantity: Int
        var budget: Double
        var attempts: Int
        var pinned: Bool
        var source: String
        var specialty: String
        var locale: String
        var ward: String
        var status: DenialBatchStatus

        init(code: String, label: String, quantity: Int, budget: Double, attempts: Int, pinned: Bool, source: String, specialty: String, locale: String, ward: String, status: DenialBatchStatus) {
            self.code = code
            self.label = label
            self.quantity = quantity
            self.budget = budget
            self.attempts = attempts
            self.pinned = pinned
            self.source = source
            self.specialty = specialty
            self.locale = locale
            self.ward = ward
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

        func canMoveTo(_ next: DenialBatchStatus) -> Bool {
            switch status {
            case .planned:
                return next == DenialBatchStatus.scheduled
            case .scheduled:
                return next == DenialBatchStatus.inProgress
            case .inProgress:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == DenialBatchStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DenialBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("denial batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("denial batch") \(code)"
        }

        func adjustedExposure() -> Double {
            return (Double(quantity) * budget * 100).rounded() / 100
        }

        func copyValue() -> DenialBatch {
            return DenialBatch(
                code: code,
                label: label,
                quantity: quantity,
                budget: budget,
                attempts: attempts,
                pinned: pinned,
                source: source,
                specialty: specialty,
                locale: locale,
                ward: ward,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a denial batch in status planned.
    static func newDenialBatch(_ code: String, label: String) -> DenialBatch {
        return DenialBatch(
            code: code,
            label: label,
            quantity: 0,
            budget: 0.0,
            attempts: 0,
            pinned: false,
            source: "",
            specialty: "",
            locale: "",
            ward: "",
            status: DenialBatchStatus.planned
        )
    }
}
