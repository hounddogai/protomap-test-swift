import AcmePlatform
import Foundation

extension Consent {
    /// Where a consent form bundle is in its life cycle.
    enum ConsentFormBundleStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One consent form bundle, with what the planners need to act on it.
    final class ConsentFormBundle {
        var code: String
        var name: String
        var copay: Double
        var sequence: Int
        var externalRef: String
        var quantity: Int
        var updatedAt: Int
        var label: String
        var status: ConsentFormBundleStatus

        init(code: String, name: String, copay: Double, sequence: Int, externalRef: String, quantity: Int, updatedAt: Int, label: String, status: ConsentFormBundleStatus) {
            self.code = code
            self.name = name
            self.copay = copay
            self.sequence = sequence
            self.externalRef = externalRef
            self.quantity = quantity
            self.updatedAt = updatedAt
            self.label = label
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

        func canMoveTo(_ next: ConsentFormBundleStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == ConsentFormBundleStatus.completed
            case .inProgress:
                return next == ConsentFormBundleStatus.completed || next == ConsentFormBundleStatus.cancelled
            case .completed:
                return next == ConsentFormBundleStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ConsentFormBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("consent form bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("consent form bundle") \(code)"
        }

        func effectiveLoad() -> Double {
            return (Double(updatedAt) * Double(quantity) * 100).rounded() / 100
        }

        func copyValue() -> ConsentFormBundle {
            return ConsentFormBundle(
                code: code,
                name: name,
                copay: copay,
                sequence: sequence,
                externalRef: externalRef,
                quantity: quantity,
                updatedAt: updatedAt,
                label: label,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a consent form bundle in status planned.
    static func newConsentFormBundle(_ code: String, name: String) -> ConsentFormBundle {
        return ConsentFormBundle(
            code: code,
            name: name,
            copay: 0.0,
            sequence: 0,
            externalRef: "",
            quantity: 0,
            updatedAt: 0,
            label: "",
            status: ConsentFormBundleStatus.planned
        )
    }
}
