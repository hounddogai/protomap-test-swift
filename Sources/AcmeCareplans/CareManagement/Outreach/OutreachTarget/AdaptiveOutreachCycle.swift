import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a adaptive outreach cycle is in its life cycle.
    enum AdaptiveOutreachCycleStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A adaptive outreach cycle as the outreach team keeps it.
    final class AdaptiveOutreachCycle {
        var code: String
        var name: String
        var payer: String
        var updatedAt: Int
        var bed: String
        var encounterID: String
        var status: AdaptiveOutreachCycleStatus

        init(code: String, name: String, payer: String, updatedAt: Int, bed: String, encounterID: String, status: AdaptiveOutreachCycleStatus) {
            self.code = code
            self.name = name
            self.payer = payer
            self.updatedAt = updatedAt
            self.bed = bed
            self.encounterID = encounterID
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

        func canMoveTo(_ next: AdaptiveOutreachCycleStatus) -> Bool {
            switch status {
            case .`open`:
                return next == AdaptiveOutreachCycleStatus.resolved
            case .inReview:
                switch next {
                case .reopened:
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
                switch next {
                case .archived:
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

        func moveTo(_ next: AdaptiveOutreachCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive outreach cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("adaptive outreach cycle") \(code)"
        }

        func measuredValue() -> Double {
            return Double(updatedAt)
        }

        func copyValue() -> AdaptiveOutreachCycle {
            return AdaptiveOutreachCycle(
                code: code,
                name: name,
                payer: payer,
                updatedAt: updatedAt,
                bed: bed,
                encounterID: encounterID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a adaptive outreach cycle in status open.
    static func newAdaptiveOutreachCycle(_ code: String, name: String) -> AdaptiveOutreachCycle {
        return AdaptiveOutreachCycle(
            code: code,
            name: name,
            payer: "",
            updatedAt: 0,
            bed: "",
            encounterID: "",
            status: AdaptiveOutreachCycleStatus.`open`
        )
    }
}
