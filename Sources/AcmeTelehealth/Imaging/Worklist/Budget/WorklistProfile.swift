import AcmePlatform
import Foundation

extension Imaging {
    /// Where a worklist profile is in its life cycle.
    enum WorklistProfileStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A worklist profile as the worklist team keeps it.
    final class WorklistProfile {
        var code: String
        var label: String
        var dosageMg: Double
        var createdAt: Int
        var amount: Double
        var clinicianID: String
        var payer: String
        var title: String
        var approved: Bool
        var minimum: Double
        var score: Double
        var status: WorklistProfileStatus

        init(code: String, label: String, dosageMg: Double, createdAt: Int, amount: Double, clinicianID: String, payer: String, title: String, approved: Bool, minimum: Double, score: Double, status: WorklistProfileStatus) {
            self.code = code
            self.label = label
            self.dosageMg = dosageMg
            self.createdAt = createdAt
            self.amount = amount
            self.clinicianID = clinicianID
            self.payer = payer
            self.title = title
            self.approved = approved
            self.minimum = minimum
            self.score = score
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

        func canMoveTo(_ next: WorklistProfileStatus) -> Bool {
            switch status {
            case .draft:
                return next == WorklistProfileStatus.pending || next == WorklistProfileStatus.closed
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

        func moveTo(_ next: WorklistProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("worklist profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("worklist profile") \(code)"
        }

        func weightedTotal() -> Double {
            return ((Double(createdAt) - dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> WorklistProfile {
            return WorklistProfile(
                code: code,
                label: label,
                dosageMg: dosageMg,
                createdAt: createdAt,
                amount: amount,
                clinicianID: clinicianID,
                payer: payer,
                title: title,
                approved: approved,
                minimum: minimum,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a worklist profile in status draft.
    static func newWorklistProfile(_ code: String, label: String) -> WorklistProfile {
        return WorklistProfile(
            code: code,
            label: label,
            dosageMg: 0.0,
            createdAt: 0,
            amount: 0.0,
            clinicianID: "",
            payer: "",
            title: "",
            approved: false,
            minimum: 0.0,
            score: 0.0,
            status: WorklistProfileStatus.draft
        )
    }
}
