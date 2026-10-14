import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a formulary checkpoint is in its life cycle.
    enum FormularyCheckpointStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A formulary checkpoint. Its code is unique within a tenant.
    final class FormularyCheckpoint {
        var code: String
        var name: String
        var title: String
        var checksum: String
        var updatedAt: Int
        var specialty: String
        var channel: String
        var allergy: String
        var category: String
        var endsAt: Int
        var status: FormularyCheckpointStatus

        init(code: String, name: String, title: String, checksum: String, updatedAt: Int, specialty: String, channel: String, allergy: String, category: String, endsAt: Int, status: FormularyCheckpointStatus) {
            self.code = code
            self.name = name
            self.title = title
            self.checksum = checksum
            self.updatedAt = updatedAt
            self.specialty = specialty
            self.channel = channel
            self.allergy = allergy
            self.category = category
            self.endsAt = endsAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FormularyCheckpointStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == FormularyCheckpointStatus.archived
            case .resolved:
                return next == FormularyCheckpointStatus.archived
            case .reopened:
                return next == FormularyCheckpointStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FormularyCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("formulary checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("formulary checkpoint") \(code)"
        }

        func effectiveLoad() -> Double {
            return (Double(updatedAt) * Double(endsAt) * 100).rounded() / 100
        }

        func copyValue() -> FormularyCheckpoint {
            return FormularyCheckpoint(
                code: code,
                name: name,
                title: title,
                checksum: checksum,
                updatedAt: updatedAt,
                specialty: specialty,
                channel: channel,
                allergy: allergy,
                category: category,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a formulary checkpoint in status open.
    static func newFormularyCheckpoint(_ code: String, name: String) -> FormularyCheckpoint {
        return FormularyCheckpoint(
            code: code,
            name: name,
            title: "",
            checksum: "",
            updatedAt: 0,
            specialty: "",
            channel: "",
            allergy: "",
            category: "",
            endsAt: 0,
            status: FormularyCheckpointStatus.`open`
        )
    }
}
