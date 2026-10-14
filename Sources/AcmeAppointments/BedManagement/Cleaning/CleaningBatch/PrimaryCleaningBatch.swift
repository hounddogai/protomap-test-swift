import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a primary cleaning batch is in its life cycle.
    enum PrimaryCleaningBatchStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A primary cleaning batch as the cleaning team keeps it.
    final class PrimaryCleaningBatch {
        var code: String
        var name: String
        var floorValue: Double
        var expiresAt: Int
        var label: String
        var visitMinutes: Int
        var capacity: Int
        var channel: String
        var payer: String
        var visible: Bool
        var attributes: [String: String]
        var status: PrimaryCleaningBatchStatus

        init(code: String, name: String, floorValue: Double, expiresAt: Int, label: String, visitMinutes: Int, capacity: Int, channel: String, payer: String, visible: Bool, attributes: [String: String], status: PrimaryCleaningBatchStatus) {
            self.code = code
            self.name = name
            self.floorValue = floorValue
            self.expiresAt = expiresAt
            self.label = label
            self.visitMinutes = visitMinutes
            self.capacity = capacity
            self.channel = channel
            self.payer = payer
            self.visible = visible
            self.attributes = attributes
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

        func canMoveTo(_ next: PrimaryCleaningBatchStatus) -> Bool {
            switch status {
            case .planned:
                return next == PrimaryCleaningBatchStatus.scheduled || next == PrimaryCleaningBatchStatus.cancelled
            case .scheduled:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == PrimaryCleaningBatchStatus.completed || next == PrimaryCleaningBatchStatus.cancelled
            case .completed:
                return next == PrimaryCleaningBatchStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryCleaningBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary cleaning batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(name)]"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func effectiveTotal() -> Double {
            return (floorValue * Double(capacity) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryCleaningBatch {
            return PrimaryCleaningBatch(
                code: code,
                name: name,
                floorValue: floorValue,
                expiresAt: expiresAt,
                label: label,
                visitMinutes: visitMinutes,
                capacity: capacity,
                channel: channel,
                payer: payer,
                visible: visible,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a primary cleaning batch in status planned.
    static func newPrimaryCleaningBatch(_ code: String, name: String) -> PrimaryCleaningBatch {
        return PrimaryCleaningBatch(
            code: code,
            name: name,
            floorValue: 0.0,
            expiresAt: 0,
            label: "",
            visitMinutes: 0,
            capacity: 0,
            channel: "",
            payer: "",
            visible: false,
            attributes: [:],
            status: PrimaryCleaningBatchStatus.planned
        )
    }
}
