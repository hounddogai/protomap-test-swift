import AcmePlatform
import Foundation

extension Referrals {
    /// Where a global network record is in its life cycle.
    enum GlobalNetworkRecordStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A global network record. Its code is unique within a tenant.
    final class GlobalNetworkRecord {
        var code: String
        var label: String
        var source: String
        var maximum: Double
        var patientRef: String
        var attributes: [String: String]
        var rate: Double
        var encounterID: String
        var retries: Int
        var status: GlobalNetworkRecordStatus

        init(code: String, label: String, source: String, maximum: Double, patientRef: String, attributes: [String: String], rate: Double, encounterID: String, retries: Int, status: GlobalNetworkRecordStatus) {
            self.code = code
            self.label = label
            self.source = source
            self.maximum = maximum
            self.patientRef = patientRef
            self.attributes = attributes
            self.rate = rate
            self.encounterID = encounterID
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

        func canMoveTo(_ next: GlobalNetworkRecordStatus) -> Bool {
            switch status {
            case .proposed:
                return next == GlobalNetworkRecordStatus.rejected || next == GlobalNetworkRecordStatus.withdrawn
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: GlobalNetworkRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global network record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
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

        func adjustedLoad() -> Double {
            return ((rate - Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> GlobalNetworkRecord {
            return GlobalNetworkRecord(
                code: code,
                label: label,
                source: source,
                maximum: maximum,
                patientRef: patientRef,
                attributes: attributes,
                rate: rate,
                encounterID: encounterID,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a global network record in status proposed.
    static func newGlobalNetworkRecord(_ code: String, label: String) -> GlobalNetworkRecord {
        return GlobalNetworkRecord(
            code: code,
            label: label,
            source: "",
            maximum: 0.0,
            patientRef: "",
            attributes: [:],
            rate: 0.0,
            encounterID: "",
            retries: 0,
            status: GlobalNetworkRecordStatus.proposed
        )
    }
}
