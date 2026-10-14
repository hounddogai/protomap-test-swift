import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a dispense entry is in its life cycle.
    enum DispenseEntryStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a dispense entry and its current status.
    final class DispenseEntry {
        var code: String
        var title: String
        var durationMinutes: Int
        var threshold: Double
        var ownerID: String
        var discount: Double
        var floorValue: Double
        var specialty: String
        var active: Bool
        var clinicianID: String
        var archived: Bool
        var status: DispenseEntryStatus

        init(code: String, title: String, durationMinutes: Int, threshold: Double, ownerID: String, discount: Double, floorValue: Double, specialty: String, active: Bool, clinicianID: String, archived: Bool, status: DispenseEntryStatus) {
            self.code = code
            self.title = title
            self.durationMinutes = durationMinutes
            self.threshold = threshold
            self.ownerID = ownerID
            self.discount = discount
            self.floorValue = floorValue
            self.specialty = specialty
            self.active = active
            self.clinicianID = clinicianID
            self.archived = archived
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

        func canMoveTo(_ next: DispenseEntryStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == DispenseEntryStatus.published
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

        func moveTo(_ next: DispenseEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("dispense entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("dispense entry") \(code)"
        }

        func projectedLoad() -> Double {
            return ((floorValue - Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> DispenseEntry {
            return DispenseEntry(
                code: code,
                title: title,
                durationMinutes: durationMinutes,
                threshold: threshold,
                ownerID: ownerID,
                discount: discount,
                floorValue: floorValue,
                specialty: specialty,
                active: active,
                clinicianID: clinicianID,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a dispense entry in status created.
    static func newDispenseEntry(_ code: String, title: String) -> DispenseEntry {
        return DispenseEntry(
            code: code,
            title: title,
            durationMinutes: 0,
            threshold: 0.0,
            ownerID: "",
            discount: 0.0,
            floorValue: 0.0,
            specialty: "",
            active: false,
            clinicianID: "",
            archived: false,
            status: DispenseEntryStatus.created
        )
    }
}
