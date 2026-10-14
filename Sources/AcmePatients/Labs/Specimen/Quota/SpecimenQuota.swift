import AcmePlatform
import Foundation

extension Labs {
    /// Where a specimen quota is in its life cycle.
    enum SpecimenQuotaStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A specimen quota. Its code is unique within a tenant.
    final class SpecimenQuota {
        var code: String
        var name: String
        var margin: Double
        var facility: String
        var specialty: String
        var ceiling: Double
        var reviewer: String
        var ratio: Double
        var active: Bool
        var ward: String
        var cost: Double
        var status: SpecimenQuotaStatus

        init(code: String, name: String, margin: Double, facility: String, specialty: String, ceiling: Double, reviewer: String, ratio: Double, active: Bool, ward: String, cost: Double, status: SpecimenQuotaStatus) {
            self.code = code
            self.name = name
            self.margin = margin
            self.facility = facility
            self.specialty = specialty
            self.ceiling = ceiling
            self.reviewer = reviewer
            self.ratio = ratio
            self.active = active
            self.ward = ward
            self.cost = cost
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

        func canMoveTo(_ next: SpecimenQuotaStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == SpecimenQuotaStatus.withdrawn
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

        func moveTo(_ next: SpecimenQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("specimen quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("specimen quota") \(code)"
        }

        func weightedValue() -> Double {
            return ((ceiling + ratio) * 100).rounded() / 100
        }

        func copyValue() -> SpecimenQuota {
            return SpecimenQuota(
                code: code,
                name: name,
                margin: margin,
                facility: facility,
                specialty: specialty,
                ceiling: ceiling,
                reviewer: reviewer,
                ratio: ratio,
                active: active,
                ward: ward,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a specimen quota in status proposed.
    static func newSpecimenQuota(_ code: String, name: String) -> SpecimenQuota {
        return SpecimenQuota(
            code: code,
            name: name,
            margin: 0.0,
            facility: "",
            specialty: "",
            ceiling: 0.0,
            reviewer: "",
            ratio: 0.0,
            active: false,
            ward: "",
            cost: 0.0,
            status: SpecimenQuotaStatus.proposed
        )
    }
}
