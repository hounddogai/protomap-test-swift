import AcmePlatform
import Foundation

extension Imaging {
    /// Where a modality assignment is in its life cycle.
    enum ModalityAssignmentStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A modality assignment as the modality team keeps it.
    final class ModalityAssignment {
        var code: String
        var name: String
        var ratio: Double
        var expiresAt: Int
        var cost: Double
        var version: Int
        var notes: String
        var quantity: Int
        var acuity: Int
        var description: String
        var attributes: [String: String]
        var status: ModalityAssignmentStatus

        init(code: String, name: String, ratio: Double, expiresAt: Int, cost: Double, version: Int, notes: String, quantity: Int, acuity: Int, description: String, attributes: [String: String], status: ModalityAssignmentStatus) {
            self.code = code
            self.name = name
            self.ratio = ratio
            self.expiresAt = expiresAt
            self.cost = cost
            self.version = version
            self.notes = notes
            self.quantity = quantity
            self.acuity = acuity
            self.description = description
            self.attributes = attributes
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

        func canMoveTo(_ next: ModalityAssignmentStatus) -> Bool {
            switch status {
            case .created:
                return next == ModalityAssignmentStatus.validated || next == ModalityAssignmentStatus.retired
            case .validated:
                return next == ModalityAssignmentStatus.published
            case .published:
                return next == ModalityAssignmentStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ModalityAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("modality assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\("modality assignment") \(code)"
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

        func effectiveValue() -> Double {
            return (cost * Double(acuity) * 100).rounded() / 100
        }

        func copyValue() -> ModalityAssignment {
            return ModalityAssignment(
                code: code,
                name: name,
                ratio: ratio,
                expiresAt: expiresAt,
                cost: cost,
                version: version,
                notes: notes,
                quantity: quantity,
                acuity: acuity,
                description: description,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a modality assignment in status created.
    static func newModalityAssignment(_ code: String, name: String) -> ModalityAssignment {
        return ModalityAssignment(
            code: code,
            name: name,
            ratio: 0.0,
            expiresAt: 0,
            cost: 0.0,
            version: 0,
            notes: "",
            quantity: 0,
            acuity: 0,
            description: "",
            attributes: [:],
            status: ModalityAssignmentStatus.created
        )
    }
}
