import AcmePlatform
import Foundation

extension Imaging {
    /// Where a global read mapping is in its life cycle.
    enum GlobalReadMappingStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A global read mapping as the read team keeps it.
    final class GlobalReadMapping {
        var code: String
        var label: String
        var cost: Double
        var clinicianID: String
        var region: String
        var version: Int
        var status: GlobalReadMappingStatus

        init(code: String, label: String, cost: Double, clinicianID: String, region: String, version: Int, status: GlobalReadMappingStatus) {
            self.code = code
            self.label = label
            self.cost = cost
            self.clinicianID = clinicianID
            self.region = region
            self.version = version
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

        func canMoveTo(_ next: GlobalReadMappingStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .rejected:
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
                return next == GlobalReadMappingStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalReadMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global read mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func weightedTotal() -> Double {
            return ((Double(version) - cost) * 100).rounded() / 100
        }

        func copyValue() -> GlobalReadMapping {
            return GlobalReadMapping(
                code: code,
                label: label,
                cost: cost,
                clinicianID: clinicianID,
                region: region,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a global read mapping in status proposed.
    static func newGlobalReadMapping(_ code: String, label: String) -> GlobalReadMapping {
        return GlobalReadMapping(
            code: code,
            label: label,
            cost: 0.0,
            clinicianID: "",
            region: "",
            version: 0,
            status: GlobalReadMappingStatus.proposed
        )
    }
}
