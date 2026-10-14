import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a global denial manifest is in its life cycle.
    enum GlobalDenialManifestStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a global denial manifest and its current status.
    final class GlobalDenialManifest {
        var code: String
        var name: String
        var weight: Double
        var description: String
        var phone: String
        var attributes: [String: String]
        var expiresAt: Int
        var notes: String
        var dosageMg: Double
        var summary: String
        var status: GlobalDenialManifestStatus

        init(code: String, name: String, weight: Double, description: String, phone: String, attributes: [String: String], expiresAt: Int, notes: String, dosageMg: Double, summary: String, status: GlobalDenialManifestStatus) {
            self.code = code
            self.name = name
            self.weight = weight
            self.description = description
            self.phone = phone
            self.attributes = attributes
            self.expiresAt = expiresAt
            self.notes = notes
            self.dosageMg = dosageMg
            self.summary = summary
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

        func canMoveTo(_ next: GlobalDenialManifestStatus) -> Bool {
            switch status {
            case .created:
                return next == GlobalDenialManifestStatus.retired
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == GlobalDenialManifestStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalDenialManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global denial manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
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

        func projectedLoad() -> Double {
            return ((Double(expiresAt) + weight) * 100).rounded() / 100
        }

        func copyValue() -> GlobalDenialManifest {
            return GlobalDenialManifest(
                code: code,
                name: name,
                weight: weight,
                description: description,
                phone: phone,
                attributes: attributes,
                expiresAt: expiresAt,
                notes: notes,
                dosageMg: dosageMg,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a global denial manifest in status created.
    static func newGlobalDenialManifest(_ code: String, name: String) -> GlobalDenialManifest {
        return GlobalDenialManifest(
            code: code,
            name: name,
            weight: 0.0,
            description: "",
            phone: "",
            attributes: [:],
            expiresAt: 0,
            notes: "",
            dosageMg: 0.0,
            summary: "",
            status: GlobalDenialManifestStatus.created
        )
    }
}
