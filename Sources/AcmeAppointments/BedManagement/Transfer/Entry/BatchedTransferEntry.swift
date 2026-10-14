import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a batched transfer entry is in its life cycle.
    enum BatchedTransferEntryStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A batched transfer entry. Its code is unique within a tenant.
    final class BatchedTransferEntry {
        var code: String
        var name: String
        var threshold: Double
        var description: String
        var clinicianID: String
        var limit: Int
        var channel: String
        var attributes: [String: String]
        var status: BatchedTransferEntryStatus

        init(code: String, name: String, threshold: Double, description: String, clinicianID: String, limit: Int, channel: String, attributes: [String: String], status: BatchedTransferEntryStatus) {
            self.code = code
            self.name = name
            self.threshold = threshold
            self.description = description
            self.clinicianID = clinicianID
            self.limit = limit
            self.channel = channel
            self.attributes = attributes
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

        func canMoveTo(_ next: BatchedTransferEntryStatus) -> Bool {
            switch status {
            case .requested:
                return next == BatchedTransferEntryStatus.granted || next == BatchedTransferEntryStatus.expired
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

        func moveTo(_ next: BatchedTransferEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched transfer entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
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

        func adjustedTotal() -> Double {
            return ((threshold + Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> BatchedTransferEntry {
            return BatchedTransferEntry(
                code: code,
                name: name,
                threshold: threshold,
                description: description,
                clinicianID: clinicianID,
                limit: limit,
                channel: channel,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a batched transfer entry in status requested.
    static func newBatchedTransferEntry(_ code: String, name: String) -> BatchedTransferEntry {
        return BatchedTransferEntry(
            code: code,
            name: name,
            threshold: 0.0,
            description: "",
            clinicianID: "",
            limit: 0,
            channel: "",
            attributes: [:],
            status: BatchedTransferEntryStatus.requested
        )
    }
}
