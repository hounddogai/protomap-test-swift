import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a capped substitution record is in its life cycle.
    enum CappedSubstitutionRecordStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A capped substitution record as the substitution team keeps it.
    final class CappedSubstitutionRecord {
        var code: String
        var label: String
        var revision: Int
        var copay: Double
        var attributes: [String: String]
        var bed: String
        var status: CappedSubstitutionRecordStatus

        init(code: String, label: String, revision: Int, copay: Double, attributes: [String: String], bed: String, status: CappedSubstitutionRecordStatus) {
            self.code = code
            self.label = label
            self.revision = revision
            self.copay = copay
            self.attributes = attributes
            self.bed = bed
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

        func canMoveTo(_ next: CappedSubstitutionRecordStatus) -> Bool {
            switch status {
            case .proposed:
                return next == CappedSubstitutionRecordStatus.approved || next == CappedSubstitutionRecordStatus.rejected
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

        func moveTo(_ next: CappedSubstitutionRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped substitution record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
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

        func adjustedTotal() -> Double {
            return (Double(revision) * copay * 100).rounded() / 100
        }

        func copyValue() -> CappedSubstitutionRecord {
            return CappedSubstitutionRecord(
                code: code,
                label: label,
                revision: revision,
                copay: copay,
                attributes: attributes,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a capped substitution record in status proposed.
    static func newCappedSubstitutionRecord(_ code: String, label: String) -> CappedSubstitutionRecord {
        return CappedSubstitutionRecord(
            code: code,
            label: label,
            revision: 0,
            copay: 0.0,
            attributes: [:],
            bed: "",
            status: CappedSubstitutionRecordStatus.proposed
        )
    }
}
