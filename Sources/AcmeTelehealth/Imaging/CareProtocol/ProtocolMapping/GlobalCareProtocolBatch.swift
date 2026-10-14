import AcmePlatform
import Foundation

extension Imaging {
    /// Where a global care protocol batch is in its life cycle.
    enum GlobalCareProtocolBatchStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One global care protocol batch, with what the planners need to act on it.
    final class GlobalCareProtocolBatch {
        var code: String
        var label: String
        var phone: String
        var segment: String
        var source: String
        var encounterID: String
        var ratio: Double
        var contactEmail: String
        var discount: Double
        var attributes: [String: String]
        var title: String
        var status: GlobalCareProtocolBatchStatus

        init(code: String, label: String, phone: String, segment: String, source: String, encounterID: String, ratio: Double, contactEmail: String, discount: Double, attributes: [String: String], title: String, status: GlobalCareProtocolBatchStatus) {
            self.code = code
            self.label = label
            self.phone = phone
            self.segment = segment
            self.source = source
            self.encounterID = encounterID
            self.ratio = ratio
            self.contactEmail = contactEmail
            self.discount = discount
            self.attributes = attributes
            self.title = title
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

        func canMoveTo(_ next: GlobalCareProtocolBatchStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == GlobalCareProtocolBatchStatus.revoked || next == GlobalCareProtocolBatchStatus.expired
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

        func moveTo(_ next: GlobalCareProtocolBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global care protocol batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
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

        func weightedVolume() -> Double {
            return (ratio * discount * 100).rounded() / 100
        }

        func copyValue() -> GlobalCareProtocolBatch {
            return GlobalCareProtocolBatch(
                code: code,
                label: label,
                phone: phone,
                segment: segment,
                source: source,
                encounterID: encounterID,
                ratio: ratio,
                contactEmail: contactEmail,
                discount: discount,
                attributes: attributes,
                title: title,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a global care protocol batch in status requested.
    static func newGlobalCareProtocolBatch(_ code: String, label: String) -> GlobalCareProtocolBatch {
        return GlobalCareProtocolBatch(
            code: code,
            label: label,
            phone: "",
            segment: "",
            source: "",
            encounterID: "",
            ratio: 0.0,
            contactEmail: "",
            discount: 0.0,
            attributes: [:],
            title: "",
            status: GlobalCareProtocolBatchStatus.requested
        )
    }
}
