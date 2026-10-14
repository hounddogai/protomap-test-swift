import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a remittance manifest is in its life cycle.
    enum RemittanceManifestStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One remittance manifest, with what the planners need to act on it.
    final class RemittanceManifest {
        var code: String
        var label: String
        var currency: String
        var approved: Bool
        var reviewer: String
        var updatedAt: Int
        var capacity: Int
        var quantity: Int
        var weight: Double
        var encounterID: String
        var status: RemittanceManifestStatus

        init(code: String, label: String, currency: String, approved: Bool, reviewer: String, updatedAt: Int, capacity: Int, quantity: Int, weight: Double, encounterID: String, status: RemittanceManifestStatus) {
            self.code = code
            self.label = label
            self.currency = currency
            self.approved = approved
            self.reviewer = reviewer
            self.updatedAt = updatedAt
            self.capacity = capacity
            self.quantity = quantity
            self.weight = weight
            self.encounterID = encounterID
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

        func canMoveTo(_ next: RemittanceManifestStatus) -> Bool {
            switch status {
            case .created:
                return next == RemittanceManifestStatus.validated
            case .validated:
                return next == RemittanceManifestStatus.published || next == RemittanceManifestStatus.retired
            case .published:
                return next == RemittanceManifestStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RemittanceManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("remittance manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func weightedValue() -> Double {
            return ((Double(capacity) - Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> RemittanceManifest {
            return RemittanceManifest(
                code: code,
                label: label,
                currency: currency,
                approved: approved,
                reviewer: reviewer,
                updatedAt: updatedAt,
                capacity: capacity,
                quantity: quantity,
                weight: weight,
                encounterID: encounterID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a remittance manifest in status created.
    static func newRemittanceManifest(_ code: String, label: String) -> RemittanceManifest {
        return RemittanceManifest(
            code: code,
            label: label,
            currency: "",
            approved: false,
            reviewer: "",
            updatedAt: 0,
            capacity: 0,
            quantity: 0,
            weight: 0.0,
            encounterID: "",
            status: RemittanceManifestStatus.created
        )
    }
}
