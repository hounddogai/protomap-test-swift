import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a capped bed board reservation is in its life cycle.
    enum CappedBedBoardReservationStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A capped bed board reservation. Its code is unique within a tenant.
    final class CappedBedBoardReservation {
        var code: String
        var name: String
        var clinicianID: String
        var refills: Int
        var checksum: String
        var maximum: Double
        var description: String
        var attempts: Int
        var country: String
        var status: CappedBedBoardReservationStatus

        init(code: String, name: String, clinicianID: String, refills: Int, checksum: String, maximum: Double, description: String, attempts: Int, country: String, status: CappedBedBoardReservationStatus) {
            self.code = code
            self.name = name
            self.clinicianID = clinicianID
            self.refills = refills
            self.checksum = checksum
            self.maximum = maximum
            self.description = description
            self.attempts = attempts
            self.country = country
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

        func canMoveTo(_ next: CappedBedBoardReservationStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == CappedBedBoardReservationStatus.resolved || next == CappedBedBoardReservationStatus.archived
            case .resolved:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == CappedBedBoardReservationStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedBedBoardReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped bed board reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func adjustedExposure() -> Double {
            return ((Double(refills) + maximum) * 100).rounded() / 100
        }

        func copyValue() -> CappedBedBoardReservation {
            return CappedBedBoardReservation(
                code: code,
                name: name,
                clinicianID: clinicianID,
                refills: refills,
                checksum: checksum,
                maximum: maximum,
                description: description,
                attempts: attempts,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a capped bed board reservation in status open.
    static func newCappedBedBoardReservation(_ code: String, name: String) -> CappedBedBoardReservation {
        return CappedBedBoardReservation(
            code: code,
            name: name,
            clinicianID: "",
            refills: 0,
            checksum: "",
            maximum: 0.0,
            description: "",
            attempts: 0,
            country: "",
            status: CappedBedBoardReservationStatus.`open`
        )
    }
}
