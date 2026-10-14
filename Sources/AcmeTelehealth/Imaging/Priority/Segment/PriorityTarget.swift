import AcmePlatform
import Foundation

extension Imaging {
    /// Where a priority target is in its life cycle.
    enum PriorityTargetStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A priority target. Its code is unique within a tenant.
    final class PriorityTarget {
        var code: String
        var label: String
        var source: String
        var discount: Double
        var currency: String
        var contactEmail: String
        var durationMinutes: Int
        var expiresAt: Int
        var createdAt: Int
        var status: PriorityTargetStatus

        init(code: String, label: String, source: String, discount: Double, currency: String, contactEmail: String, durationMinutes: Int, expiresAt: Int, createdAt: Int, status: PriorityTargetStatus) {
            self.code = code
            self.label = label
            self.source = source
            self.discount = discount
            self.currency = currency
            self.contactEmail = contactEmail
            self.durationMinutes = durationMinutes
            self.expiresAt = expiresAt
            self.createdAt = createdAt
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

        func canMoveTo(_ next: PriorityTargetStatus) -> Bool {
            switch status {
            case .planned:
                return next == PriorityTargetStatus.scheduled || next == PriorityTargetStatus.cancelled
            case .scheduled:
                return next == PriorityTargetStatus.completed
            case .inProgress:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: PriorityTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("priority target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func adjustedLoad() -> Double {
            return (Double(createdAt) * Double(durationMinutes) * 100).rounded() / 100
        }

        func copyValue() -> PriorityTarget {
            return PriorityTarget(
                code: code,
                label: label,
                source: source,
                discount: discount,
                currency: currency,
                contactEmail: contactEmail,
                durationMinutes: durationMinutes,
                expiresAt: expiresAt,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a priority target in status planned.
    static func newPriorityTarget(_ code: String, label: String) -> PriorityTarget {
        return PriorityTarget(
            code: code,
            label: label,
            source: "",
            discount: 0.0,
            currency: "",
            contactEmail: "",
            durationMinutes: 0,
            expiresAt: 0,
            createdAt: 0,
            status: PriorityTargetStatus.planned
        )
    }
}
