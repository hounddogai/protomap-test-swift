import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a risk score baseline is in its life cycle.
    enum RiskScoreBaselineStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A risk score baseline. Its code is unique within a tenant.
    final class RiskScoreBaseline {
        var code: String
        var name: String
        var refills: Int
        var updatedAt: Int
        var timezone: String
        var visitMinutes: Int
        var weight: Double
        var tags: [String]
        var copay: Double
        var endsAt: Int
        var status: RiskScoreBaselineStatus

        init(code: String, name: String, refills: Int, updatedAt: Int, timezone: String, visitMinutes: Int, weight: Double, tags: [String], copay: Double, endsAt: Int, status: RiskScoreBaselineStatus) {
            self.code = code
            self.name = name
            self.refills = refills
            self.updatedAt = updatedAt
            self.timezone = timezone
            self.visitMinutes = visitMinutes
            self.weight = weight
            self.tags = tags
            self.copay = copay
            self.endsAt = endsAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RiskScoreBaselineStatus) -> Bool {
            switch status {
            case .created:
                return next == RiskScoreBaselineStatus.retired
            case .validated:
                return next == RiskScoreBaselineStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: RiskScoreBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("risk score baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func adjustedExposure() -> Double {
            return ((copay + Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> RiskScoreBaseline {
            return RiskScoreBaseline(
                code: code,
                name: name,
                refills: refills,
                updatedAt: updatedAt,
                timezone: timezone,
                visitMinutes: visitMinutes,
                weight: weight,
                tags: tags,
                copay: copay,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a risk score baseline in status created.
    static func newRiskScoreBaseline(_ code: String, name: String) -> RiskScoreBaseline {
        return RiskScoreBaseline(
            code: code,
            name: name,
            refills: 0,
            updatedAt: 0,
            timezone: "",
            visitMinutes: 0,
            weight: 0.0,
            tags: [],
            copay: 0.0,
            endsAt: 0,
            status: RiskScoreBaselineStatus.created
        )
    }
}
