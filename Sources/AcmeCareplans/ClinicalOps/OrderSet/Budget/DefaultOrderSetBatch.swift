import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a default order set batch is in its life cycle.
    enum DefaultOrderSetBatchStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A default order set batch. Its code is unique within a tenant.
    final class DefaultOrderSetBatch {
        var code: String
        var label: String
        var attempts: Int
        var createdAt: Int
        var channel: String
        var minimum: Double
        var floorValue: Double
        var region: String
        var visible: Bool
        var title: String
        var encounterID: String
        var status: DefaultOrderSetBatchStatus

        init(code: String, label: String, attempts: Int, createdAt: Int, channel: String, minimum: Double, floorValue: Double, region: String, visible: Bool, title: String, encounterID: String, status: DefaultOrderSetBatchStatus) {
            self.code = code
            self.label = label
            self.attempts = attempts
            self.createdAt = createdAt
            self.channel = channel
            self.minimum = minimum
            self.floorValue = floorValue
            self.region = region
            self.visible = visible
            self.title = title
            self.encounterID = encounterID
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

        func canMoveTo(_ next: DefaultOrderSetBatchStatus) -> Bool {
            switch status {
            case .requested:
                return next == DefaultOrderSetBatchStatus.revoked
            case .granted:
                return next == DefaultOrderSetBatchStatus.revoked
            case .revoked:
                return next == DefaultOrderSetBatchStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultOrderSetBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default order set batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func effectiveExposure() -> Double {
            return ((floorValue + Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> DefaultOrderSetBatch {
            return DefaultOrderSetBatch(
                code: code,
                label: label,
                attempts: attempts,
                createdAt: createdAt,
                channel: channel,
                minimum: minimum,
                floorValue: floorValue,
                region: region,
                visible: visible,
                title: title,
                encounterID: encounterID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a default order set batch in status requested.
    static func newDefaultOrderSetBatch(_ code: String, label: String) -> DefaultOrderSetBatch {
        return DefaultOrderSetBatch(
            code: code,
            label: label,
            attempts: 0,
            createdAt: 0,
            channel: "",
            minimum: 0.0,
            floorValue: 0.0,
            region: "",
            visible: false,
            title: "",
            encounterID: "",
            status: DefaultOrderSetBatchStatus.requested
        )
    }
}
