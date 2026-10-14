import AcmePlatform
import Foundation

extension Referrals {
    /// Where a adaptive network snapshot is in its life cycle.
    enum AdaptiveNetworkSnapshotStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A adaptive network snapshot as the network team keeps it.
    final class AdaptiveNetworkSnapshot {
        var code: String
        var label: String
        var batchSize: Int
        var tags: [String]
        var discount: Double
        var endsAt: Int
        var patientRef: String
        var status: AdaptiveNetworkSnapshotStatus

        init(code: String, label: String, batchSize: Int, tags: [String], discount: Double, endsAt: Int, patientRef: String, status: AdaptiveNetworkSnapshotStatus) {
            self.code = code
            self.label = label
            self.batchSize = batchSize
            self.tags = tags
            self.discount = discount
            self.endsAt = endsAt
            self.patientRef = patientRef
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

        func canMoveTo(_ next: AdaptiveNetworkSnapshotStatus) -> Bool {
            switch status {
            case .requested:
                return next == AdaptiveNetworkSnapshotStatus.granted
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: AdaptiveNetworkSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive network snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func adjustedVolume() -> Double {
            return ((discount + Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveNetworkSnapshot {
            return AdaptiveNetworkSnapshot(
                code: code,
                label: label,
                batchSize: batchSize,
                tags: tags,
                discount: discount,
                endsAt: endsAt,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a adaptive network snapshot in status requested.
    static func newAdaptiveNetworkSnapshot(_ code: String, label: String) -> AdaptiveNetworkSnapshot {
        return AdaptiveNetworkSnapshot(
            code: code,
            label: label,
            batchSize: 0,
            tags: [],
            discount: 0.0,
            endsAt: 0,
            patientRef: "",
            status: AdaptiveNetworkSnapshotStatus.requested
        )
    }
}
