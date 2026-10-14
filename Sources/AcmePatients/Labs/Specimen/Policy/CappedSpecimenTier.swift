import AcmePlatform
import Foundation

extension Labs {
    /// Where a capped specimen tier is in its life cycle.
    enum CappedSpecimenTierStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One capped specimen tier, with what the planners need to act on it.
    final class CappedSpecimenTier {
        var code: String
        var name: String
        var refills: Int
        var summary: String
        var margin: Double
        var score: Double
        var quantity: Int
        var allergy: String
        var discount: Double
        var notes: String
        var unit: String
        var status: CappedSpecimenTierStatus

        init(code: String, name: String, refills: Int, summary: String, margin: Double, score: Double, quantity: Int, allergy: String, discount: Double, notes: String, unit: String, status: CappedSpecimenTierStatus) {
            self.code = code
            self.name = name
            self.refills = refills
            self.summary = summary
            self.margin = margin
            self.score = score
            self.quantity = quantity
            self.allergy = allergy
            self.discount = discount
            self.notes = notes
            self.unit = unit
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

        func canMoveTo(_ next: CappedSpecimenTierStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == CappedSpecimenTierStatus.suspended || next == CappedSpecimenTierStatus.closed
            case .suspended:
                return next == CappedSpecimenTierStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedSpecimenTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped specimen tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func projectedValue() -> Double {
            return ((Double(quantity) + discount) * 100).rounded() / 100
        }

        func copyValue() -> CappedSpecimenTier {
            return CappedSpecimenTier(
                code: code,
                name: name,
                refills: refills,
                summary: summary,
                margin: margin,
                score: score,
                quantity: quantity,
                allergy: allergy,
                discount: discount,
                notes: notes,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a capped specimen tier in status draft.
    static func newCappedSpecimenTier(_ code: String, name: String) -> CappedSpecimenTier {
        return CappedSpecimenTier(
            code: code,
            name: name,
            refills: 0,
            summary: "",
            margin: 0.0,
            score: 0.0,
            quantity: 0,
            allergy: "",
            discount: 0.0,
            notes: "",
            unit: "",
            status: CappedSpecimenTierStatus.draft
        )
    }
}
