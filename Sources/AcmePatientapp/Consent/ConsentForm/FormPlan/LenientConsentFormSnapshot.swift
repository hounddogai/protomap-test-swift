import AcmePlatform
import Foundation

extension Consent {
    /// Where a lenient consent form snapshot is in its life cycle.
    enum LenientConsentFormSnapshotStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a lenient consent form snapshot and its current status.
    final class LenientConsentFormSnapshot {
        var code: String
        var title: String
        var maximum: Double
        var procedureCode: String
        var cost: Double
        var capacity: Int
        var quantity: Int
        var attempts: Int
        var summary: String
        var status: LenientConsentFormSnapshotStatus

        init(code: String, title: String, maximum: Double, procedureCode: String, cost: Double, capacity: Int, quantity: Int, attempts: Int, summary: String, status: LenientConsentFormSnapshotStatus) {
            self.code = code
            self.title = title
            self.maximum = maximum
            self.procedureCode = procedureCode
            self.cost = cost
            self.capacity = capacity
            self.quantity = quantity
            self.attempts = attempts
            self.summary = summary
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LenientConsentFormSnapshotStatus) -> Bool {
            switch status {
            case .requested:
                return next == LenientConsentFormSnapshotStatus.granted || next == LenientConsentFormSnapshotStatus.revoked
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: LenientConsentFormSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient consent form snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func effectiveExposure() -> Double {
            return ((Double(capacity) - Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> LenientConsentFormSnapshot {
            return LenientConsentFormSnapshot(
                code: code,
                title: title,
                maximum: maximum,
                procedureCode: procedureCode,
                cost: cost,
                capacity: capacity,
                quantity: quantity,
                attempts: attempts,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a lenient consent form snapshot in status requested.
    static func newLenientConsentFormSnapshot(_ code: String, title: String) -> LenientConsentFormSnapshot {
        return LenientConsentFormSnapshot(
            code: code,
            title: title,
            maximum: 0.0,
            procedureCode: "",
            cost: 0.0,
            capacity: 0,
            quantity: 0,
            attempts: 0,
            summary: "",
            status: LenientConsentFormSnapshotStatus.requested
        )
    }
}
