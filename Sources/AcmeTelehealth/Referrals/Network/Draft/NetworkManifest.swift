import AcmePlatform
import Foundation

extension Referrals {
    /// Where a network manifest is in its life cycle.
    enum NetworkManifestStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A network manifest as the network team keeps it.
    final class NetworkManifest {
        var code: String
        var label: String
        var allergy: String
        var endsAt: Int
        var sequence: Int
        var status: NetworkManifestStatus

        init(code: String, label: String, allergy: String, endsAt: Int, sequence: Int, status: NetworkManifestStatus) {
            self.code = code
            self.label = label
            self.allergy = allergy
            self.endsAt = endsAt
            self.sequence = sequence
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

        func canMoveTo(_ next: NetworkManifestStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == NetworkManifestStatus.active || next == NetworkManifestStatus.suspended
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: NetworkManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("network manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func projectedLoad() -> Double {
            return ((Double(sequence) - Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> NetworkManifest {
            return NetworkManifest(
                code: code,
                label: label,
                allergy: allergy,
                endsAt: endsAt,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a network manifest in status draft.
    static func newNetworkManifest(_ code: String, label: String) -> NetworkManifest {
        return NetworkManifest(
            code: code,
            label: label,
            allergy: "",
            endsAt: 0,
            sequence: 0,
            status: NetworkManifestStatus.draft
        )
    }
}
