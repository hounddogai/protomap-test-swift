import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a fallback isolation manifest is in its life cycle.
    enum FallbackIsolationManifestStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A fallback isolation manifest. Its code is unique within a tenant.
    final class FallbackIsolationManifest {
        var code: String
        var name: String
        var updatedAt: Int
        var weight: Double
        var attributes: [String: String]
        var status: FallbackIsolationManifestStatus

        init(code: String, name: String, updatedAt: Int, weight: Double, attributes: [String: String], status: FallbackIsolationManifestStatus) {
            self.code = code
            self.name = name
            self.updatedAt = updatedAt
            self.weight = weight
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

        func canMoveTo(_ next: FallbackIsolationManifestStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == FallbackIsolationManifestStatus.retired
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

        func moveTo(_ next: FallbackIsolationManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback isolation manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("fallback isolation manifest") \(code)"
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

        func netValue() -> Double {
            return ((Double(updatedAt) + weight) * 100).rounded() / 100
        }

        func copyValue() -> FallbackIsolationManifest {
            return FallbackIsolationManifest(
                code: code,
                name: name,
                updatedAt: updatedAt,
                weight: weight,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a fallback isolation manifest in status created.
    static func newFallbackIsolationManifest(_ code: String, name: String) -> FallbackIsolationManifest {
        return FallbackIsolationManifest(
            code: code,
            name: name,
            updatedAt: 0,
            weight: 0.0,
            attributes: [:],
            status: FallbackIsolationManifestStatus.created
        )
    }
}
