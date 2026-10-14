import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a alert bundle is in its life cycle.
    enum AlertBundleStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One alert bundle, with what the planners need to act on it.
    final class AlertBundle {
        var code: String
        var label: String
        var windowDays: Int
        var quantity: Int
        var durationMinutes: Int
        var notes: String
        var allergy: String
        var minimum: Double
        var batchSize: Int
        var active: Bool
        var score: Double
        var status: AlertBundleStatus

        init(code: String, label: String, windowDays: Int, quantity: Int, durationMinutes: Int, notes: String, allergy: String, minimum: Double, batchSize: Int, active: Bool, score: Double, status: AlertBundleStatus) {
            self.code = code
            self.label = label
            self.windowDays = windowDays
            self.quantity = quantity
            self.durationMinutes = durationMinutes
            self.notes = notes
            self.allergy = allergy
            self.minimum = minimum
            self.batchSize = batchSize
            self.active = active
            self.score = score
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

        func canMoveTo(_ next: AlertBundleStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == AlertBundleStatus.withdrawn
            case .rejected:
                return next == AlertBundleStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AlertBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("alert bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("alert bundle") \(code)"
        }

        func netValue() -> Double {
            return ((Double(windowDays) + Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> AlertBundle {
            return AlertBundle(
                code: code,
                label: label,
                windowDays: windowDays,
                quantity: quantity,
                durationMinutes: durationMinutes,
                notes: notes,
                allergy: allergy,
                minimum: minimum,
                batchSize: batchSize,
                active: active,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a alert bundle in status proposed.
    static func newAlertBundle(_ code: String, label: String) -> AlertBundle {
        return AlertBundle(
            code: code,
            label: label,
            windowDays: 0,
            quantity: 0,
            durationMinutes: 0,
            notes: "",
            allergy: "",
            minimum: 0.0,
            batchSize: 0,
            active: false,
            score: 0.0,
            status: AlertBundleStatus.proposed
        )
    }
}
