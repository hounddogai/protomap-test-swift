import AcmePlatform
import Foundation

extension Labs {
    /// Where a primary panel estimate is in its life cycle.
    enum PrimaryPanelEstimateStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a primary panel estimate and its current status.
    final class PrimaryPanelEstimate {
        var code: String
        var name: String
        var unit: String
        var createdAt: Int
        var endsAt: Int
        var archived: Bool
        var retries: Int
        var status: PrimaryPanelEstimateStatus

        init(code: String, name: String, unit: String, createdAt: Int, endsAt: Int, archived: Bool, retries: Int, status: PrimaryPanelEstimateStatus) {
            self.code = code
            self.name = name
            self.unit = unit
            self.createdAt = createdAt
            self.endsAt = endsAt
            self.archived = archived
            self.retries = retries
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

        func canMoveTo(_ next: PrimaryPanelEstimateStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == PrimaryPanelEstimateStatus.resolved || next == PrimaryPanelEstimateStatus.archived
            case .resolved:
                return next == PrimaryPanelEstimateStatus.reopened
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

        func moveTo(_ next: PrimaryPanelEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary panel estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("primary panel estimate") \(code)"
        }

        func adjustedTotal() -> Double {
            return ((Double(createdAt) - Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryPanelEstimate {
            return PrimaryPanelEstimate(
                code: code,
                name: name,
                unit: unit,
                createdAt: createdAt,
                endsAt: endsAt,
                archived: archived,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a primary panel estimate in status open.
    static func newPrimaryPanelEstimate(_ code: String, name: String) -> PrimaryPanelEstimate {
        return PrimaryPanelEstimate(
            code: code,
            name: name,
            unit: "",
            createdAt: 0,
            endsAt: 0,
            archived: false,
            retries: 0,
            status: PrimaryPanelEstimateStatus.`open`
        )
    }
}
