import AcmePlatform
import Foundation

extension Consent {
    /// Where a regional witness batch is in its life cycle.
    enum RegionalWitnessBatchStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One regional witness batch, with what the planners need to act on it.
    final class RegionalWitnessBatch {
        var code: String
        var label: String
        var updatedAt: Int
        var minimum: Double
        var batchSize: Int
        var quantity: Int
        var country: String
        var facility: String
        var priority: Int
        var status: RegionalWitnessBatchStatus

        init(code: String, label: String, updatedAt: Int, minimum: Double, batchSize: Int, quantity: Int, country: String, facility: String, priority: Int, status: RegionalWitnessBatchStatus) {
            self.code = code
            self.label = label
            self.updatedAt = updatedAt
            self.minimum = minimum
            self.batchSize = batchSize
            self.quantity = quantity
            self.country = country
            self.facility = facility
            self.priority = priority
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

        func canMoveTo(_ next: RegionalWitnessBatchStatus) -> Bool {
            switch status {
            case .proposed:
                return next == RegionalWitnessBatchStatus.approved || next == RegionalWitnessBatchStatus.rejected
            case .approved:
                return next == RegionalWitnessBatchStatus.rejected || next == RegionalWitnessBatchStatus.withdrawn
            case .rejected:
                return next == RegionalWitnessBatchStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalWitnessBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional witness batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func projectedExposure() -> Double {
            return ((Double(batchSize) + Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> RegionalWitnessBatch {
            return RegionalWitnessBatch(
                code: code,
                label: label,
                updatedAt: updatedAt,
                minimum: minimum,
                batchSize: batchSize,
                quantity: quantity,
                country: country,
                facility: facility,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a regional witness batch in status proposed.
    static func newRegionalWitnessBatch(_ code: String, label: String) -> RegionalWitnessBatch {
        return RegionalWitnessBatch(
            code: code,
            label: label,
            updatedAt: 0,
            minimum: 0.0,
            batchSize: 0,
            quantity: 0,
            country: "",
            facility: "",
            priority: 0,
            status: RegionalWitnessBatchStatus.proposed
        )
    }
}
