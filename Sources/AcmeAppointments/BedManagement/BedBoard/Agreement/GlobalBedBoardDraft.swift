import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a global bed board draft is in its life cycle.
    enum GlobalBedBoardDraftStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A global bed board draft as the bed board team keeps it.
    final class GlobalBedBoardDraft {
        var code: String
        var label: String
        var margin: Double
        var ratio: Double
        var updatedAt: Int
        var allergy: String
        var summary: String
        var dosageMg: Double
        var status: GlobalBedBoardDraftStatus

        init(code: String, label: String, margin: Double, ratio: Double, updatedAt: Int, allergy: String, summary: String, dosageMg: Double, status: GlobalBedBoardDraftStatus) {
            self.code = code
            self.label = label
            self.margin = margin
            self.ratio = ratio
            self.updatedAt = updatedAt
            self.allergy = allergy
            self.summary = summary
            self.dosageMg = dosageMg
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: GlobalBedBoardDraftStatus) -> Bool {
            switch status {
            case .requested:
                return next == GlobalBedBoardDraftStatus.revoked || next == GlobalBedBoardDraftStatus.expired
            case .granted:
                return next == GlobalBedBoardDraftStatus.expired
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: GlobalBedBoardDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global bed board draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("global bed board draft") \(code)"
        }

        func projectedValue() -> Double {
            return ((Double(updatedAt) + dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> GlobalBedBoardDraft {
            return GlobalBedBoardDraft(
                code: code,
                label: label,
                margin: margin,
                ratio: ratio,
                updatedAt: updatedAt,
                allergy: allergy,
                summary: summary,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a global bed board draft in status requested.
    static func newGlobalBedBoardDraft(_ code: String, label: String) -> GlobalBedBoardDraft {
        return GlobalBedBoardDraft(
            code: code,
            label: label,
            margin: 0.0,
            ratio: 0.0,
            updatedAt: 0,
            allergy: "",
            summary: "",
            dosageMg: 0.0,
            status: GlobalBedBoardDraftStatus.requested
        )
    }
}
