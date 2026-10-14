import AcmePlatform
import Foundation

extension Consent {
    /// Where a batched witness bundle is in its life cycle.
    enum BatchedWitnessBundleStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One batched witness bundle, with what the planners need to act on it.
    final class BatchedWitnessBundle {
        var code: String
        var name: String
        var batchSize: Int
        var contactEmail: String
        var attributes: [String: String]
        var notes: String
        var specialty: String
        var status: BatchedWitnessBundleStatus

        init(code: String, name: String, batchSize: Int, contactEmail: String, attributes: [String: String], notes: String, specialty: String, status: BatchedWitnessBundleStatus) {
            self.code = code
            self.name = name
            self.batchSize = batchSize
            self.contactEmail = contactEmail
            self.attributes = attributes
            self.notes = notes
            self.specialty = specialty
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

        func canMoveTo(_ next: BatchedWitnessBundleStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == BatchedWitnessBundleStatus.rejected || next == BatchedWitnessBundleStatus.withdrawn
            case .rejected:
                return next == BatchedWitnessBundleStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedWitnessBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched witness bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("batched witness bundle") \(code)"
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

        func measuredValue() -> Double {
            return Double(batchSize)
        }

        func copyValue() -> BatchedWitnessBundle {
            return BatchedWitnessBundle(
                code: code,
                name: name,
                batchSize: batchSize,
                contactEmail: contactEmail,
                attributes: attributes,
                notes: notes,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a batched witness bundle in status proposed.
    static func newBatchedWitnessBundle(_ code: String, name: String) -> BatchedWitnessBundle {
        return BatchedWitnessBundle(
            code: code,
            name: name,
            batchSize: 0,
            contactEmail: "",
            attributes: [:],
            notes: "",
            specialty: "",
            status: BatchedWitnessBundleStatus.proposed
        )
    }
}
