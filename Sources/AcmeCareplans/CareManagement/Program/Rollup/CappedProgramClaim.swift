import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a capped program claim is in its life cycle.
    enum CappedProgramClaimStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A capped program claim as the program team keeps it.
    final class CappedProgramClaim {
        var code: String
        var title: String
        var tags: [String]
        var bed: String
        var windowDays: Int
        var region: String
        var quantity: Int
        var status: CappedProgramClaimStatus

        init(code: String, title: String, tags: [String], bed: String, windowDays: Int, region: String, quantity: Int, status: CappedProgramClaimStatus) {
            self.code = code
            self.title = title
            self.tags = tags
            self.bed = bed
            self.windowDays = windowDays
            self.region = region
            self.quantity = quantity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CappedProgramClaimStatus) -> Bool {
            switch status {
            case .planned:
                return next == CappedProgramClaimStatus.scheduled
            case .scheduled:
                return next == CappedProgramClaimStatus.completed || next == CappedProgramClaimStatus.cancelled
            case .inProgress:
                return next == CappedProgramClaimStatus.completed || next == CappedProgramClaimStatus.cancelled
            case .completed:
                return next == CappedProgramClaimStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedProgramClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped program claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedExposure() -> Double {
            return ((Double(windowDays) + Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> CappedProgramClaim {
            return CappedProgramClaim(
                code: code,
                title: title,
                tags: tags,
                bed: bed,
                windowDays: windowDays,
                region: region,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a capped program claim in status planned.
    static func newCappedProgramClaim(_ code: String, title: String) -> CappedProgramClaim {
        return CappedProgramClaim(
            code: code,
            title: title,
            tags: [],
            bed: "",
            windowDays: 0,
            region: "",
            quantity: 0,
            status: CappedProgramClaimStatus.planned
        )
    }
}
