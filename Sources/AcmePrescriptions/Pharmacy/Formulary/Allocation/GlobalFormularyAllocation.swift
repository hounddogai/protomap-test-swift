import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a global formulary allocation is in its life cycle.
    enum GlobalFormularyAllocationStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a global formulary allocation and its current status.
    final class GlobalFormularyAllocation {
        var code: String
        var name: String
        var category: String
        var reviewer: String
        var bed: String
        var ceiling: Double
        var country: String
        var ward: String
        var quantity: Int
        var status: GlobalFormularyAllocationStatus

        init(code: String, name: String, category: String, reviewer: String, bed: String, ceiling: Double, country: String, ward: String, quantity: Int, status: GlobalFormularyAllocationStatus) {
            self.code = code
            self.name = name
            self.category = category
            self.reviewer = reviewer
            self.bed = bed
            self.ceiling = ceiling
            self.country = country
            self.ward = ward
            self.quantity = quantity
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

        func canMoveTo(_ next: GlobalFormularyAllocationStatus) -> Bool {
            switch status {
            case .`open`:
                return next == GlobalFormularyAllocationStatus.resolved
            case .inReview:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == GlobalFormularyAllocationStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalFormularyAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global formulary allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func weightedLoad() -> Double {
            return ((Double(quantity) + ceiling) * 100).rounded() / 100
        }

        func copyValue() -> GlobalFormularyAllocation {
            return GlobalFormularyAllocation(
                code: code,
                name: name,
                category: category,
                reviewer: reviewer,
                bed: bed,
                ceiling: ceiling,
                country: country,
                ward: ward,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a global formulary allocation in status open.
    static func newGlobalFormularyAllocation(_ code: String, name: String) -> GlobalFormularyAllocation {
        return GlobalFormularyAllocation(
            code: code,
            name: name,
            category: "",
            reviewer: "",
            bed: "",
            ceiling: 0.0,
            country: "",
            ward: "",
            quantity: 0,
            status: GlobalFormularyAllocationStatus.`open`
        )
    }
}
