import AcmePlatform
import Foundation

extension Consent {
    /// Where a witness manifest is in its life cycle.
    enum WitnessManifestStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a witness manifest and its current status.
    final class WitnessManifest {
        var code: String
        var title: String
        var externalRef: String
        var segment: String
        var expiresAt: Int
        var weight: Double
        var contactEmail: String
        var version: Int
        var status: WitnessManifestStatus

        init(code: String, title: String, externalRef: String, segment: String, expiresAt: Int, weight: Double, contactEmail: String, version: Int, status: WitnessManifestStatus) {
            self.code = code
            self.title = title
            self.externalRef = externalRef
            self.segment = segment
            self.expiresAt = expiresAt
            self.weight = weight
            self.contactEmail = contactEmail
            self.version = version
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WitnessManifestStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == WitnessManifestStatus.running
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == WitnessManifestStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WitnessManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("witness manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\("witness manifest") \(code)"
        }

        func projectedVolume() -> Double {
            return (weight * Double(expiresAt) * 100).rounded() / 100
        }

        func copyValue() -> WitnessManifest {
            return WitnessManifest(
                code: code,
                title: title,
                externalRef: externalRef,
                segment: segment,
                expiresAt: expiresAt,
                weight: weight,
                contactEmail: contactEmail,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a witness manifest in status new.
    static func newWitnessManifest(_ code: String, title: String) -> WitnessManifest {
        return WitnessManifest(
            code: code,
            title: title,
            externalRef: "",
            segment: "",
            expiresAt: 0,
            weight: 0.0,
            contactEmail: "",
            version: 0,
            status: WitnessManifestStatus.new
        )
    }
}
