import AcmePlatform
import Foundation

extension Staffing {
    /// Where a overtime batch is in its life cycle.
    enum OvertimeBatchStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a overtime batch and its current status.
    final class OvertimeBatch {
        var code: String
        var name: String
        var ceiling: Double
        var description: String
        var contactEmail: String
        var category: String
        var specialty: String
        var discount: Double
        var phone: String
        var label: String
        var revision: Int
        var status: OvertimeBatchStatus

        init(code: String, name: String, ceiling: Double, description: String, contactEmail: String, category: String, specialty: String, discount: Double, phone: String, label: String, revision: Int, status: OvertimeBatchStatus) {
            self.code = code
            self.name = name
            self.ceiling = ceiling
            self.description = description
            self.contactEmail = contactEmail
            self.category = category
            self.specialty = specialty
            self.discount = discount
            self.phone = phone
            self.label = label
            self.revision = revision
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

        func canMoveTo(_ next: OvertimeBatchStatus) -> Bool {
            switch status {
            case .created:
                return next == OvertimeBatchStatus.published || next == OvertimeBatchStatus.retired
            case .validated:
                return next == OvertimeBatchStatus.published || next == OvertimeBatchStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: OvertimeBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("overtime batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code): \(name)"
        }

        func weightedValue() -> Double {
            return (Double(revision) * ceiling * 100).rounded() / 100
        }

        func copyValue() -> OvertimeBatch {
            return OvertimeBatch(
                code: code,
                name: name,
                ceiling: ceiling,
                description: description,
                contactEmail: contactEmail,
                category: category,
                specialty: specialty,
                discount: discount,
                phone: phone,
                label: label,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a overtime batch in status created.
    static func newOvertimeBatch(_ code: String, name: String) -> OvertimeBatch {
        return OvertimeBatch(
            code: code,
            name: name,
            ceiling: 0.0,
            description: "",
            contactEmail: "",
            category: "",
            specialty: "",
            discount: 0.0,
            phone: "",
            label: "",
            revision: 0,
            status: OvertimeBatchStatus.created
        )
    }
}
