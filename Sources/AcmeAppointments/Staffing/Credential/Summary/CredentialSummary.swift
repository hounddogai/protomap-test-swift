import AcmePlatform
import Foundation

extension Staffing {
    /// Where a credential summary is in its life cycle.
    enum CredentialSummaryStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A credential summary as the credential team keeps it.
    final class CredentialSummary {
        var code: String
        var name: String
        var encounterID: String
        var allergy: String
        var updatedAt: Int
        var retries: Int
        var checksum: String
        var channel: String
        var ceiling: Double
        var tags: [String]
        var attributes: [String: String]
        var status: CredentialSummaryStatus

        init(code: String, name: String, encounterID: String, allergy: String, updatedAt: Int, retries: Int, checksum: String, channel: String, ceiling: Double, tags: [String], attributes: [String: String], status: CredentialSummaryStatus) {
            self.code = code
            self.name = name
            self.encounterID = encounterID
            self.allergy = allergy
            self.updatedAt = updatedAt
            self.retries = retries
            self.checksum = checksum
            self.channel = channel
            self.ceiling = ceiling
            self.tags = tags
            self.attributes = attributes
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

        func canMoveTo(_ next: CredentialSummaryStatus) -> Bool {
            switch status {
            case .created:
                return next == CredentialSummaryStatus.validated || next == CredentialSummaryStatus.published
            case .validated:
                return next == CredentialSummaryStatus.published || next == CredentialSummaryStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: CredentialSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("credential summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
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

        func netVolume() -> Double {
            return ((Double(updatedAt) + Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> CredentialSummary {
            return CredentialSummary(
                code: code,
                name: name,
                encounterID: encounterID,
                allergy: allergy,
                updatedAt: updatedAt,
                retries: retries,
                checksum: checksum,
                channel: channel,
                ceiling: ceiling,
                tags: tags,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a credential summary in status created.
    static func newCredentialSummary(_ code: String, name: String) -> CredentialSummary {
        return CredentialSummary(
            code: code,
            name: name,
            encounterID: "",
            allergy: "",
            updatedAt: 0,
            retries: 0,
            checksum: "",
            channel: "",
            ceiling: 0.0,
            tags: [],
            attributes: [:],
            status: CredentialSummaryStatus.created
        )
    }
}
