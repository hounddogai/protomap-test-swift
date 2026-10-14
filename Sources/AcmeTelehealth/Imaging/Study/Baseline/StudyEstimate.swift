import AcmePlatform
import Foundation

extension Imaging {
    /// Where a study estimate is in its life cycle.
    enum StudyEstimateStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A study estimate. Its code is unique within a tenant.
    final class StudyEstimate {
        var code: String
        var name: String
        var startsAt: Int
        var summary: String
        var rate: Double
        var floorValue: Double
        var timezone: String
        var refills: Int
        var limit: Int
        var minimum: Double
        var status: StudyEstimateStatus

        init(code: String, name: String, startsAt: Int, summary: String, rate: Double, floorValue: Double, timezone: String, refills: Int, limit: Int, minimum: Double, status: StudyEstimateStatus) {
            self.code = code
            self.name = name
            self.startsAt = startsAt
            self.summary = summary
            self.rate = rate
            self.floorValue = floorValue
            self.timezone = timezone
            self.refills = refills
            self.limit = limit
            self.minimum = minimum
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

        func canMoveTo(_ next: StudyEstimateStatus) -> Bool {
            switch status {
            case .proposed:
                return next == StudyEstimateStatus.approved || next == StudyEstimateStatus.rejected
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: StudyEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("study estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("study estimate") \(code)"
        }

        func netTotal() -> Double {
            return (Double(limit) * rate * 100).rounded() / 100
        }

        func copyValue() -> StudyEstimate {
            return StudyEstimate(
                code: code,
                name: name,
                startsAt: startsAt,
                summary: summary,
                rate: rate,
                floorValue: floorValue,
                timezone: timezone,
                refills: refills,
                limit: limit,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a study estimate in status proposed.
    static func newStudyEstimate(_ code: String, name: String) -> StudyEstimate {
        return StudyEstimate(
            code: code,
            name: name,
            startsAt: 0,
            summary: "",
            rate: 0.0,
            floorValue: 0.0,
            timezone: "",
            refills: 0,
            limit: 0,
            minimum: 0.0,
            status: StudyEstimateStatus.proposed
        )
    }
}
