import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a discharge plan notice is in its life cycle.
    enum DischargePlanNoticeStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One discharge plan notice, with what the planners need to act on it.
    final class DischargePlanNotice {
        var code: String
        var name: String
        var limit: Int
        var budget: Double
        var margin: Double
        var reviewer: String
        var checksum: String
        var region: String
        var active: Bool
        var status: DischargePlanNoticeStatus

        init(code: String, name: String, limit: Int, budget: Double, margin: Double, reviewer: String, checksum: String, region: String, active: Bool, status: DischargePlanNoticeStatus) {
            self.code = code
            self.name = name
            self.limit = limit
            self.budget = budget
            self.margin = margin
            self.reviewer = reviewer
            self.checksum = checksum
            self.region = region
            self.active = active
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DischargePlanNoticeStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == DischargePlanNoticeStatus.withdrawn
            case .rejected:
                return next == DischargePlanNoticeStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DischargePlanNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("discharge plan notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("discharge plan notice") \(code)"
        }

        func projectedExposure() -> Double {
            return ((budget + Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> DischargePlanNotice {
            return DischargePlanNotice(
                code: code,
                name: name,
                limit: limit,
                budget: budget,
                margin: margin,
                reviewer: reviewer,
                checksum: checksum,
                region: region,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a discharge plan notice in status proposed.
    static func newDischargePlanNotice(_ code: String, name: String) -> DischargePlanNotice {
        return DischargePlanNotice(
            code: code,
            name: name,
            limit: 0,
            budget: 0.0,
            margin: 0.0,
            reviewer: "",
            checksum: "",
            region: "",
            active: false,
            status: DischargePlanNoticeStatus.proposed
        )
    }
}
