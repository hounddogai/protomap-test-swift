import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a regional handoff manifest is in its life cycle.
    enum RegionalHandoffManifestStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A regional handoff manifest as the handoff team keeps it.
    final class RegionalHandoffManifest {
        var code: String
        var label: String
        var batchSize: Int
        var facility: String
        var bed: String
        var graceDays: Int
        var status: RegionalHandoffManifestStatus

        init(code: String, label: String, batchSize: Int, facility: String, bed: String, graceDays: Int, status: RegionalHandoffManifestStatus) {
            self.code = code
            self.label = label
            self.batchSize = batchSize
            self.facility = facility
            self.bed = bed
            self.graceDays = graceDays
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

        func canMoveTo(_ next: RegionalHandoffManifestStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == RegionalHandoffManifestStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalHandoffManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional handoff manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func effectiveTotal() -> Double {
            return ((Double(batchSize) + Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> RegionalHandoffManifest {
            return RegionalHandoffManifest(
                code: code,
                label: label,
                batchSize: batchSize,
                facility: facility,
                bed: bed,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a regional handoff manifest in status proposed.
    static func newRegionalHandoffManifest(_ code: String, label: String) -> RegionalHandoffManifest {
        return RegionalHandoffManifest(
            code: code,
            label: label,
            batchSize: 0,
            facility: "",
            bed: "",
            graceDays: 0,
            status: RegionalHandoffManifestStatus.proposed
        )
    }
}
