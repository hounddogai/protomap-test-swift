import AcmePlatform
import Foundation

extension Imaging {
    /// Where a default read allocation is in its life cycle.
    enum DefaultReadAllocationStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A default read allocation as the read team keeps it.
    final class DefaultReadAllocation {
        var code: String
        var label: String
        var capacity: Int
        var externalRef: String
        var version: Int
        var phone: String
        var revision: Int
        var patientRef: String
        var attributes: [String: String]
        var ward: String
        var description: String
        var status: DefaultReadAllocationStatus

        init(code: String, label: String, capacity: Int, externalRef: String, version: Int, phone: String, revision: Int, patientRef: String, attributes: [String: String], ward: String, description: String, status: DefaultReadAllocationStatus) {
            self.code = code
            self.label = label
            self.capacity = capacity
            self.externalRef = externalRef
            self.version = version
            self.phone = phone
            self.revision = revision
            self.patientRef = patientRef
            self.attributes = attributes
            self.ward = ward
            self.description = description
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DefaultReadAllocationStatus) -> Bool {
            switch status {
            case .created:
                return next == DefaultReadAllocationStatus.validated || next == DefaultReadAllocationStatus.published
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == DefaultReadAllocationStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultReadAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default read allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
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

        func effectiveTotal() -> Double {
            return ((Double(revision) + Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> DefaultReadAllocation {
            return DefaultReadAllocation(
                code: code,
                label: label,
                capacity: capacity,
                externalRef: externalRef,
                version: version,
                phone: phone,
                revision: revision,
                patientRef: patientRef,
                attributes: attributes,
                ward: ward,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a default read allocation in status created.
    static func newDefaultReadAllocation(_ code: String, label: String) -> DefaultReadAllocation {
        return DefaultReadAllocation(
            code: code,
            label: label,
            capacity: 0,
            externalRef: "",
            version: 0,
            phone: "",
            revision: 0,
            patientRef: "",
            attributes: [:],
            ward: "",
            description: "",
            status: DefaultReadAllocationStatus.created
        )
    }
}
