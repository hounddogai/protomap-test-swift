import AcmePlatform
import Foundation

extension Staffing {
    /// Where a primary acuity plan target is in its life cycle.
    enum PrimaryAcuityPlanTargetStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A primary acuity plan target as the acuity plan team keeps it.
    final class PrimaryAcuityPlanTarget {
        var code: String
        var title: String
        var version: Int
        var ward: String
        var discount: Double
        var updatedAt: Int
        var createdAt: Int
        var segment: String
        var margin: Double
        var endsAt: Int
        var status: PrimaryAcuityPlanTargetStatus

        init(code: String, title: String, version: Int, ward: String, discount: Double, updatedAt: Int, createdAt: Int, segment: String, margin: Double, endsAt: Int, status: PrimaryAcuityPlanTargetStatus) {
            self.code = code
            self.title = title
            self.version = version
            self.ward = ward
            self.discount = discount
            self.updatedAt = updatedAt
            self.createdAt = createdAt
            self.segment = segment
            self.margin = margin
            self.endsAt = endsAt
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

        func canMoveTo(_ next: PrimaryAcuityPlanTargetStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == PrimaryAcuityPlanTargetStatus.retired
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

        func moveTo(_ next: PrimaryAcuityPlanTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary acuity plan target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func projectedTotal() -> Double {
            return ((Double(updatedAt) + Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryAcuityPlanTarget {
            return PrimaryAcuityPlanTarget(
                code: code,
                title: title,
                version: version,
                ward: ward,
                discount: discount,
                updatedAt: updatedAt,
                createdAt: createdAt,
                segment: segment,
                margin: margin,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a primary acuity plan target in status created.
    static func newPrimaryAcuityPlanTarget(_ code: String, title: String) -> PrimaryAcuityPlanTarget {
        return PrimaryAcuityPlanTarget(
            code: code,
            title: title,
            version: 0,
            ward: "",
            discount: 0.0,
            updatedAt: 0,
            createdAt: 0,
            segment: "",
            margin: 0.0,
            endsAt: 0,
            status: PrimaryAcuityPlanTargetStatus.created
        )
    }
}
