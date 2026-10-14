import AcmePlatform
import Foundation

extension Consent {
    /// Where a revocation metric is in its life cycle.
    enum RevocationMetricStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One revocation metric, with what the planners need to act on it.
    final class RevocationMetric {
        var code: String
        var name: String
        var tags: [String]
        var acuity: Int
        var discount: Double
        var minimum: Double
        var approved: Bool
        var durationMinutes: Int
        var status: RevocationMetricStatus

        init(code: String, name: String, tags: [String], acuity: Int, discount: Double, minimum: Double, approved: Bool, durationMinutes: Int, status: RevocationMetricStatus) {
            self.code = code
            self.name = name
            self.tags = tags
            self.acuity = acuity
            self.discount = discount
            self.minimum = minimum
            self.approved = approved
            self.durationMinutes = durationMinutes
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

        func canMoveTo(_ next: RevocationMetricStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .withdrawn:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: RevocationMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("revocation metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("revocation metric") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func projectedExposure() -> Double {
            return (Double(durationMinutes) * minimum * 100).rounded() / 100
        }

        func copyValue() -> RevocationMetric {
            return RevocationMetric(
                code: code,
                name: name,
                tags: tags,
                acuity: acuity,
                discount: discount,
                minimum: minimum,
                approved: approved,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a revocation metric in status proposed.
    static func newRevocationMetric(_ code: String, name: String) -> RevocationMetric {
        return RevocationMetric(
            code: code,
            name: name,
            tags: [],
            acuity: 0,
            discount: 0.0,
            minimum: 0.0,
            approved: false,
            durationMinutes: 0,
            status: RevocationMetricStatus.proposed
        )
    }
}
