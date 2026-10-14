import AcmePlatform
import Foundation

extension Consent {
    /// Where a tiered revocation estimate is in its life cycle.
    enum TieredRevocationEstimateStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One tiered revocation estimate, with what the planners need to act on it.
    final class TieredRevocationEstimate {
        var code: String
        var label: String
        var endsAt: Int
        var region: String
        var startsAt: Int
        var reviewer: String
        var visible: Bool
        var acuity: Int
        var budget: Double
        var tags: [String]
        var status: TieredRevocationEstimateStatus

        init(code: String, label: String, endsAt: Int, region: String, startsAt: Int, reviewer: String, visible: Bool, acuity: Int, budget: Double, tags: [String], status: TieredRevocationEstimateStatus) {
            self.code = code
            self.label = label
            self.endsAt = endsAt
            self.region = region
            self.startsAt = startsAt
            self.reviewer = reviewer
            self.visible = visible
            self.acuity = acuity
            self.budget = budget
            self.tags = tags
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

        func canMoveTo(_ next: TieredRevocationEstimateStatus) -> Bool {
            switch status {
            case .draft:
                return next == TieredRevocationEstimateStatus.active || next == TieredRevocationEstimateStatus.closed
            case .pending:
                return next == TieredRevocationEstimateStatus.active || next == TieredRevocationEstimateStatus.closed
            case .active:
                return next == TieredRevocationEstimateStatus.suspended || next == TieredRevocationEstimateStatus.closed
            case .suspended:
                return next == TieredRevocationEstimateStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredRevocationEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered revocation estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("tiered revocation estimate") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func netTotal() -> Double {
            return ((Double(startsAt) + Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> TieredRevocationEstimate {
            return TieredRevocationEstimate(
                code: code,
                label: label,
                endsAt: endsAt,
                region: region,
                startsAt: startsAt,
                reviewer: reviewer,
                visible: visible,
                acuity: acuity,
                budget: budget,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a tiered revocation estimate in status draft.
    static func newTieredRevocationEstimate(_ code: String, label: String) -> TieredRevocationEstimate {
        return TieredRevocationEstimate(
            code: code,
            label: label,
            endsAt: 0,
            region: "",
            startsAt: 0,
            reviewer: "",
            visible: false,
            acuity: 0,
            budget: 0.0,
            tags: [],
            status: TieredRevocationEstimateStatus.draft
        )
    }
}
