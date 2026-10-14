import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a bed board rule is in its life cycle.
    enum BedBoardRuleStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One bed board rule, with what the planners need to act on it.
    final class BedBoardRule {
        var code: String
        var name: String
        var reviewer: String
        var retries: Int
        var endsAt: Int
        var checksum: String
        var limit: Int
        var status: BedBoardRuleStatus

        init(code: String, name: String, reviewer: String, retries: Int, endsAt: Int, checksum: String, limit: Int, status: BedBoardRuleStatus) {
            self.code = code
            self.name = name
            self.reviewer = reviewer
            self.retries = retries
            self.endsAt = endsAt
            self.checksum = checksum
            self.limit = limit
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

        func canMoveTo(_ next: BedBoardRuleStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == BedBoardRuleStatus.reopened
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

        func moveTo(_ next: BedBoardRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("bed board rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func projectedExposure() -> Double {
            return ((Double(retries) - Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> BedBoardRule {
            return BedBoardRule(
                code: code,
                name: name,
                reviewer: reviewer,
                retries: retries,
                endsAt: endsAt,
                checksum: checksum,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a bed board rule in status open.
    static func newBedBoardRule(_ code: String, name: String) -> BedBoardRule {
        return BedBoardRule(
            code: code,
            name: name,
            reviewer: "",
            retries: 0,
            endsAt: 0,
            checksum: "",
            limit: 0,
            status: BedBoardRuleStatus.`open`
        )
    }
}
