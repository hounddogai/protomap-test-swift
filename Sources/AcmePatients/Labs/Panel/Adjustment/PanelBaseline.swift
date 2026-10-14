import AcmePlatform
import Foundation

extension Labs {
    /// Where a panel baseline is in its life cycle.
    enum PanelBaselineStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A panel baseline. Its code is unique within a tenant.
    final class PanelBaseline {
        var code: String
        var title: String
        var updatedAt: Int
        var category: String
        var bed: String
        var procedureCode: String
        var region: String
        var amount: Double
        var status: PanelBaselineStatus

        init(code: String, title: String, updatedAt: Int, category: String, bed: String, procedureCode: String, region: String, amount: Double, status: PanelBaselineStatus) {
            self.code = code
            self.title = title
            self.updatedAt = updatedAt
            self.category = category
            self.bed = bed
            self.procedureCode = procedureCode
            self.region = region
            self.amount = amount
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

        func canMoveTo(_ next: PanelBaselineStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .closed:
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

        func moveTo(_ next: PanelBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("panel baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func netVolume() -> Double {
            return (amount * Double(updatedAt) * 100).rounded() / 100
        }

        func copyValue() -> PanelBaseline {
            return PanelBaseline(
                code: code,
                title: title,
                updatedAt: updatedAt,
                category: category,
                bed: bed,
                procedureCode: procedureCode,
                region: region,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a panel baseline in status draft.
    static func newPanelBaseline(_ code: String, title: String) -> PanelBaseline {
        return PanelBaseline(
            code: code,
            title: title,
            updatedAt: 0,
            category: "",
            bed: "",
            procedureCode: "",
            region: "",
            amount: 0.0,
            status: PanelBaselineStatus.draft
        )
    }
}
