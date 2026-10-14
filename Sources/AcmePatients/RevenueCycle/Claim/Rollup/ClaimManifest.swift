import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a claim manifest is in its life cycle.
    enum ClaimManifestStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a claim manifest and its current status.
    final class ClaimManifest {
        var code: String
        var name: String
        var maximum: Double
        var externalRef: String
        var updatedAt: Int
        var status: ClaimManifestStatus

        init(code: String, name: String, maximum: Double, externalRef: String, updatedAt: Int, status: ClaimManifestStatus) {
            self.code = code
            self.name = name
            self.maximum = maximum
            self.externalRef = externalRef
            self.updatedAt = updatedAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ClaimManifestStatus) -> Bool {
            switch status {
            case .draft:
                return next == ClaimManifestStatus.suspended
            case .pending:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == ClaimManifestStatus.suspended || next == ClaimManifestStatus.closed
            case .suspended:
                return next == ClaimManifestStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ClaimManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("claim manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("claim manifest") \(code)"
        }

        func projectedVolume() -> Double {
            return ((Double(updatedAt) - maximum) * 100).rounded() / 100
        }

        func copyValue() -> ClaimManifest {
            return ClaimManifest(
                code: code,
                name: name,
                maximum: maximum,
                externalRef: externalRef,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a claim manifest in status draft.
    static func newClaimManifest(_ code: String, name: String) -> ClaimManifest {
        return ClaimManifest(
            code: code,
            name: name,
            maximum: 0.0,
            externalRef: "",
            updatedAt: 0,
            status: ClaimManifestStatus.draft
        )
    }
}
