import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a care gap entry is in its life cycle.
    enum CareGapEntryStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a care gap entry and its current status.
    final class CareGapEntry {
        var code: String
        var name: String
        var acuity: Int
        var notes: String
        var contactEmail: String
        var allergy: String
        var minimum: Double
        var region: String
        var visitMinutes: Int
        var status: CareGapEntryStatus

        init(code: String, name: String, acuity: Int, notes: String, contactEmail: String, allergy: String, minimum: Double, region: String, visitMinutes: Int, status: CareGapEntryStatus) {
            self.code = code
            self.name = name
            self.acuity = acuity
            self.notes = notes
            self.contactEmail = contactEmail
            self.allergy = allergy
            self.minimum = minimum
            self.region = region
            self.visitMinutes = visitMinutes
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

        func canMoveTo(_ next: CareGapEntryStatus) -> Bool {
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
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == CareGapEntryStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareGapEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care gap entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("care gap entry") \(code)"
        }

        func weightedExposure() -> Double {
            return ((minimum - Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> CareGapEntry {
            return CareGapEntry(
                code: code,
                name: name,
                acuity: acuity,
                notes: notes,
                contactEmail: contactEmail,
                allergy: allergy,
                minimum: minimum,
                region: region,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a care gap entry in status proposed.
    static func newCareGapEntry(_ code: String, name: String) -> CareGapEntry {
        return CareGapEntry(
            code: code,
            name: name,
            acuity: 0,
            notes: "",
            contactEmail: "",
            allergy: "",
            minimum: 0.0,
            region: "",
            visitMinutes: 0,
            status: CareGapEntryStatus.proposed
        )
    }
}
