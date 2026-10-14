import AcmePlatform
import Foundation

extension Labs {
    /// Where a specimen assignment is in its life cycle.
    enum SpecimenAssignmentStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a specimen assignment and its current status.
    final class SpecimenAssignment {
        var code: String
        var title: String
        var amount: Double
        var locale: String
        var ward: String
        var contactEmail: String
        var bed: String
        var limit: Int
        var endsAt: Int
        var cost: Double
        var status: SpecimenAssignmentStatus

        init(code: String, title: String, amount: Double, locale: String, ward: String, contactEmail: String, bed: String, limit: Int, endsAt: Int, cost: Double, status: SpecimenAssignmentStatus) {
            self.code = code
            self.title = title
            self.amount = amount
            self.locale = locale
            self.ward = ward
            self.contactEmail = contactEmail
            self.bed = bed
            self.limit = limit
            self.endsAt = endsAt
            self.cost = cost
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SpecimenAssignmentStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == SpecimenAssignmentStatus.running || next == SpecimenAssignmentStatus.failed
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == SpecimenAssignmentStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SpecimenAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("specimen assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func adjustedTotal() -> Double {
            return (cost * amount * 100).rounded() / 100
        }

        func copyValue() -> SpecimenAssignment {
            return SpecimenAssignment(
                code: code,
                title: title,
                amount: amount,
                locale: locale,
                ward: ward,
                contactEmail: contactEmail,
                bed: bed,
                limit: limit,
                endsAt: endsAt,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a specimen assignment in status new.
    static func newSpecimenAssignment(_ code: String, title: String) -> SpecimenAssignment {
        return SpecimenAssignment(
            code: code,
            title: title,
            amount: 0.0,
            locale: "",
            ward: "",
            contactEmail: "",
            bed: "",
            limit: 0,
            endsAt: 0,
            cost: 0.0,
            status: SpecimenAssignmentStatus.new
        )
    }
}
