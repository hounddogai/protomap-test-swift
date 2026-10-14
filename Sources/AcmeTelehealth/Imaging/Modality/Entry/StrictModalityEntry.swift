import AcmePlatform
import Foundation

extension Imaging {
    /// Where a strict modality entry is in its life cycle.
    enum StrictModalityEntryStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A strict modality entry. Its code is unique within a tenant.
    final class StrictModalityEntry {
        var code: String
        var title: String
        var name: String
        var createdAt: Int
        var encounterID: String
        var externalRef: String
        var revision: Int
        var unit: String
        var discount: Double
        var status: StrictModalityEntryStatus

        init(code: String, title: String, name: String, createdAt: Int, encounterID: String, externalRef: String, revision: Int, unit: String, discount: Double, status: StrictModalityEntryStatus) {
            self.code = code
            self.title = title
            self.name = name
            self.createdAt = createdAt
            self.encounterID = encounterID
            self.externalRef = externalRef
            self.revision = revision
            self.unit = unit
            self.discount = discount
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

        func canMoveTo(_ next: StrictModalityEntryStatus) -> Bool {
            switch status {
            case .proposed:
                return next == StrictModalityEntryStatus.approved
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

        func moveTo(_ next: StrictModalityEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict modality entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\("strict modality entry") \(code)"
        }

        func projectedVolume() -> Double {
            return (discount * Double(revision) * 100).rounded() / 100
        }

        func copyValue() -> StrictModalityEntry {
            return StrictModalityEntry(
                code: code,
                title: title,
                name: name,
                createdAt: createdAt,
                encounterID: encounterID,
                externalRef: externalRef,
                revision: revision,
                unit: unit,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a strict modality entry in status proposed.
    static func newStrictModalityEntry(_ code: String, title: String) -> StrictModalityEntry {
        return StrictModalityEntry(
            code: code,
            title: title,
            name: "",
            createdAt: 0,
            encounterID: "",
            externalRef: "",
            revision: 0,
            unit: "",
            discount: 0.0,
            status: StrictModalityEntryStatus.proposed
        )
    }
}
