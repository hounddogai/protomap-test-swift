import AcmePlatform
import Foundation

extension Staffing {
    /// Where a legacy acuity plan mapping is in its life cycle.
    enum LegacyAcuityPlanMappingStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A legacy acuity plan mapping. Its code is unique within a tenant.
    final class LegacyAcuityPlanMapping {
        var code: String
        var name: String
        var payer: String
        var score: Double
        var facility: String
        var quantity: Int
        var limit: Int
        var margin: Double
        var status: LegacyAcuityPlanMappingStatus

        init(code: String, name: String, payer: String, score: Double, facility: String, quantity: Int, limit: Int, margin: Double, status: LegacyAcuityPlanMappingStatus) {
            self.code = code
            self.name = name
            self.payer = payer
            self.score = score
            self.facility = facility
            self.quantity = quantity
            self.limit = limit
            self.margin = margin
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LegacyAcuityPlanMappingStatus) -> Bool {
            switch status {
            case .draft:
                return next == LegacyAcuityPlanMappingStatus.closed
            case .pending:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: LegacyAcuityPlanMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy acuity plan mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func adjustedExposure() -> Double {
            return ((Double(quantity) - score) * 100).rounded() / 100
        }

        func copyValue() -> LegacyAcuityPlanMapping {
            return LegacyAcuityPlanMapping(
                code: code,
                name: name,
                payer: payer,
                score: score,
                facility: facility,
                quantity: quantity,
                limit: limit,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a legacy acuity plan mapping in status draft.
    static func newLegacyAcuityPlanMapping(_ code: String, name: String) -> LegacyAcuityPlanMapping {
        return LegacyAcuityPlanMapping(
            code: code,
            name: name,
            payer: "",
            score: 0.0,
            facility: "",
            quantity: 0,
            limit: 0,
            margin: 0.0,
            status: LegacyAcuityPlanMappingStatus.draft
        )
    }
}
