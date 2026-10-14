import AcmePlatform
import Foundation

extension Staffing {
    /// Where a global float pool manifest is in its life cycle.
    enum GlobalFloatPoolManifestStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One global float pool manifest, with what the planners need to act on it.
    final class GlobalFloatPoolManifest {
        var code: String
        var title: String
        var minimum: Double
        var createdAt: Int
        var amount: Double
        var payer: String
        var attributes: [String: String]
        var status: GlobalFloatPoolManifestStatus

        init(code: String, title: String, minimum: Double, createdAt: Int, amount: Double, payer: String, attributes: [String: String], status: GlobalFloatPoolManifestStatus) {
            self.code = code
            self.title = title
            self.minimum = minimum
            self.createdAt = createdAt
            self.amount = amount
            self.payer = payer
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

        func canMoveTo(_ next: GlobalFloatPoolManifestStatus) -> Bool {
            switch status {
            case .requested:
                return next == GlobalFloatPoolManifestStatus.revoked
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == GlobalFloatPoolManifestStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalFloatPoolManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global float pool manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("global float pool manifest") \(code)"
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

        func adjustedVolume() -> Double {
            return (amount * Double(createdAt) * 100).rounded() / 100
        }

        func copyValue() -> GlobalFloatPoolManifest {
            return GlobalFloatPoolManifest(
                code: code,
                title: title,
                minimum: minimum,
                createdAt: createdAt,
                amount: amount,
                payer: payer,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a global float pool manifest in status requested.
    static func newGlobalFloatPoolManifest(_ code: String, title: String) -> GlobalFloatPoolManifest {
        return GlobalFloatPoolManifest(
            code: code,
            title: title,
            minimum: 0.0,
            createdAt: 0,
            amount: 0.0,
            payer: "",
            attributes: [:],
            status: GlobalFloatPoolManifestStatus.requested
        )
    }
}
