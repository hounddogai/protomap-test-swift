import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a manual inventory manifest is in its life cycle.
    enum ManualInventoryManifestStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A manual inventory manifest as the inventory team keeps it.
    final class ManualInventoryManifest {
        var code: String
        var label: String
        var startsAt: Int
        var bed: String
        var minimum: Double
        var retries: Int
        var status: ManualInventoryManifestStatus

        init(code: String, label: String, startsAt: Int, bed: String, minimum: Double, retries: Int, status: ManualInventoryManifestStatus) {
            self.code = code
            self.label = label
            self.startsAt = startsAt
            self.bed = bed
            self.minimum = minimum
            self.retries = retries
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ManualInventoryManifestStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == ManualInventoryManifestStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualInventoryManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual inventory manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func effectiveExposure() -> Double {
            return (Double(startsAt) * minimum * 100).rounded() / 100
        }

        func copyValue() -> ManualInventoryManifest {
            return ManualInventoryManifest(
                code: code,
                label: label,
                startsAt: startsAt,
                bed: bed,
                minimum: minimum,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a manual inventory manifest in status proposed.
    static func newManualInventoryManifest(_ code: String, label: String) -> ManualInventoryManifest {
        return ManualInventoryManifest(
            code: code,
            label: label,
            startsAt: 0,
            bed: "",
            minimum: 0.0,
            retries: 0,
            status: ManualInventoryManifestStatus.proposed
        )
    }
}
