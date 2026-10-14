import AcmePlatform
import Foundation

extension Imaging {
    /// Where a read claim is in its life cycle.
    enum ReadClaimStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A read claim as the read team keeps it.
    final class ReadClaim {
        var code: String
        var name: String
        var summary: String
        var budget: Double
        var title: String
        var margin: Double
        var procedureCode: String
        var updatedAt: Int
        var status: ReadClaimStatus

        init(code: String, name: String, summary: String, budget: Double, title: String, margin: Double, procedureCode: String, updatedAt: Int, status: ReadClaimStatus) {
            self.code = code
            self.name = name
            self.summary = summary
            self.budget = budget
            self.title = title
            self.margin = margin
            self.procedureCode = procedureCode
            self.updatedAt = updatedAt
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

        func canMoveTo(_ next: ReadClaimStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active:
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
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == ReadClaimStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReadClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("read claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("read claim") \(code)"
        }

        func adjustedTotal() -> Double {
            return (Double(updatedAt) * margin * 100).rounded() / 100
        }

        func copyValue() -> ReadClaim {
            return ReadClaim(
                code: code,
                name: name,
                summary: summary,
                budget: budget,
                title: title,
                margin: margin,
                procedureCode: procedureCode,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a read claim in status draft.
    static func newReadClaim(_ code: String, name: String) -> ReadClaim {
        return ReadClaim(
            code: code,
            name: name,
            summary: "",
            budget: 0.0,
            title: "",
            margin: 0.0,
            procedureCode: "",
            updatedAt: 0,
            status: ReadClaimStatus.draft
        )
    }
}
