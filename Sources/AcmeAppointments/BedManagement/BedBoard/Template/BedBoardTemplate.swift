import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a bed board template is in its life cycle.
    enum BedBoardTemplateStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a bed board template and its current status.
    final class BedBoardTemplate {
        var code: String
        var title: String
        var createdAt: Int
        var active: Bool
        var clinicianID: String
        var floorValue: Double
        var budget: Double
        var ward: String
        var description: String
        var weight: Double
        var status: BedBoardTemplateStatus

        init(code: String, title: String, createdAt: Int, active: Bool, clinicianID: String, floorValue: Double, budget: Double, ward: String, description: String, weight: Double, status: BedBoardTemplateStatus) {
            self.code = code
            self.title = title
            self.createdAt = createdAt
            self.active = active
            self.clinicianID = clinicianID
            self.floorValue = floorValue
            self.budget = budget
            self.ward = ward
            self.description = description
            self.weight = weight
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

        func canMoveTo(_ next: BedBoardTemplateStatus) -> Bool {
            switch status {
            case .proposed:
                return next == BedBoardTemplateStatus.rejected
            case .approved:
                switch next {
                case .rejected:
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

        func moveTo(_ next: BedBoardTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("bed board template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func adjustedLoad() -> Double {
            return ((weight - budget) * 100).rounded() / 100
        }

        func copyValue() -> BedBoardTemplate {
            return BedBoardTemplate(
                code: code,
                title: title,
                createdAt: createdAt,
                active: active,
                clinicianID: clinicianID,
                floorValue: floorValue,
                budget: budget,
                ward: ward,
                description: description,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a bed board template in status proposed.
    static func newBedBoardTemplate(_ code: String, title: String) -> BedBoardTemplate {
        return BedBoardTemplate(
            code: code,
            title: title,
            createdAt: 0,
            active: false,
            clinicianID: "",
            floorValue: 0.0,
            budget: 0.0,
            ward: "",
            description: "",
            weight: 0.0,
            status: BedBoardTemplateStatus.proposed
        )
    }
}
