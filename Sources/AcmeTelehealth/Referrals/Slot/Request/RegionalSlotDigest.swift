import AcmePlatform
import Foundation

extension Referrals {
    /// Where a regional slot digest is in its life cycle.
    enum RegionalSlotDigestStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A regional slot digest as the slot team keeps it.
    final class RegionalSlotDigest {
        var code: String
        var label: String
        var createdAt: Int
        var attributes: [String: String]
        var externalRef: String
        var phone: String
        var batchSize: Int
        var status: RegionalSlotDigestStatus

        init(code: String, label: String, createdAt: Int, attributes: [String: String], externalRef: String, phone: String, batchSize: Int, status: RegionalSlotDigestStatus) {
            self.code = code
            self.label = label
            self.createdAt = createdAt
            self.attributes = attributes
            self.externalRef = externalRef
            self.phone = phone
            self.batchSize = batchSize
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

        func canMoveTo(_ next: RegionalSlotDigestStatus) -> Bool {
            switch status {
            case .requested:
                return next == RegionalSlotDigestStatus.granted || next == RegionalSlotDigestStatus.expired
            case .granted:
                return next == RegionalSlotDigestStatus.expired
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

        func moveTo(_ next: RegionalSlotDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional slot digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
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

        func netTotal() -> Double {
            return ((Double(createdAt) - Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> RegionalSlotDigest {
            return RegionalSlotDigest(
                code: code,
                label: label,
                createdAt: createdAt,
                attributes: attributes,
                externalRef: externalRef,
                phone: phone,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a regional slot digest in status requested.
    static func newRegionalSlotDigest(_ code: String, label: String) -> RegionalSlotDigest {
        return RegionalSlotDigest(
            code: code,
            label: label,
            createdAt: 0,
            attributes: [:],
            externalRef: "",
            phone: "",
            batchSize: 0,
            status: RegionalSlotDigestStatus.requested
        )
    }
}
