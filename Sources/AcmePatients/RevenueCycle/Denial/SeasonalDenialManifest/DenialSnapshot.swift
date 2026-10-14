import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a denial snapshot is in its life cycle.
    enum DenialSnapshotStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One denial snapshot, with what the planners need to act on it.
    final class DenialSnapshot {
        var code: String
        var name: String
        var budget: Double
        var facility: String
        var acuity: Int
        var discount: Double
        var encounterID: String
        var description: String
        var attempts: Int
        var currency: String
        var updatedAt: Int
        var status: DenialSnapshotStatus

        init(code: String, name: String, budget: Double, facility: String, acuity: Int, discount: Double, encounterID: String, description: String, attempts: Int, currency: String, updatedAt: Int, status: DenialSnapshotStatus) {
            self.code = code
            self.name = name
            self.budget = budget
            self.facility = facility
            self.acuity = acuity
            self.discount = discount
            self.encounterID = encounterID
            self.description = description
            self.attempts = attempts
            self.currency = currency
            self.updatedAt = updatedAt
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

        func canMoveTo(_ next: DenialSnapshotStatus) -> Bool {
            switch status {
            case .proposed:
                return next == DenialSnapshotStatus.approved || next == DenialSnapshotStatus.withdrawn
            case .approved:
                return next == DenialSnapshotStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: DenialSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("denial snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("denial snapshot") \(code)"
        }

        func effectiveVolume() -> Double {
            return ((budget - Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> DenialSnapshot {
            return DenialSnapshot(
                code: code,
                name: name,
                budget: budget,
                facility: facility,
                acuity: acuity,
                discount: discount,
                encounterID: encounterID,
                description: description,
                attempts: attempts,
                currency: currency,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a denial snapshot in status proposed.
    static func newDenialSnapshot(_ code: String, name: String) -> DenialSnapshot {
        return DenialSnapshot(
            code: code,
            name: name,
            budget: 0.0,
            facility: "",
            acuity: 0,
            discount: 0.0,
            encounterID: "",
            description: "",
            attempts: 0,
            currency: "",
            updatedAt: 0,
            status: DenialSnapshotStatus.proposed
        )
    }
}
