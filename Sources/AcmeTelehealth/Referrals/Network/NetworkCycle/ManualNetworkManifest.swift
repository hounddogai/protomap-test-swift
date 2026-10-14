import AcmePlatform
import Foundation

extension Referrals {
    /// Where a manual network manifest is in its life cycle.
    enum ManualNetworkManifestStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a manual network manifest and its current status.
    final class ManualNetworkManifest {
        var code: String
        var name: String
        var floorValue: Double
        var allergy: String
        var timezone: String
        var refills: Int
        var label: String
        var channel: String
        var status: ManualNetworkManifestStatus

        init(code: String, name: String, floorValue: Double, allergy: String, timezone: String, refills: Int, label: String, channel: String, status: ManualNetworkManifestStatus) {
            self.code = code
            self.name = name
            self.floorValue = floorValue
            self.allergy = allergy
            self.timezone = timezone
            self.refills = refills
            self.label = label
            self.channel = channel
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

        func canMoveTo(_ next: ManualNetworkManifestStatus) -> Bool {
            switch status {
            case .draft:
                return next == ManualNetworkManifestStatus.closed
            case .pending:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == ManualNetworkManifestStatus.suspended || next == ManualNetworkManifestStatus.closed
            case .suspended:
                return next == ManualNetworkManifestStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualNetworkManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual network manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(name))"
        }

        func adjustedTotal() -> Double {
            return (floorValue * Double(refills) * 100).rounded() / 100
        }

        func copyValue() -> ManualNetworkManifest {
            return ManualNetworkManifest(
                code: code,
                name: name,
                floorValue: floorValue,
                allergy: allergy,
                timezone: timezone,
                refills: refills,
                label: label,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a manual network manifest in status draft.
    static func newManualNetworkManifest(_ code: String, name: String) -> ManualNetworkManifest {
        return ManualNetworkManifest(
            code: code,
            name: name,
            floorValue: 0.0,
            allergy: "",
            timezone: "",
            refills: 0,
            label: "",
            channel: "",
            status: ManualNetworkManifestStatus.draft
        )
    }
}
