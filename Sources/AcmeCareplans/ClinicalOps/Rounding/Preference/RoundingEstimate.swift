import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a rounding estimate is in its life cycle.
    enum RoundingEstimateStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A rounding estimate. Its code is unique within a tenant.
    final class RoundingEstimate {
        var code: String
        var name: String
        var refills: Int
        var expiresAt: Int
        var dosageMg: Double
        var floorValue: Double
        var active: Bool
        var createdAt: Int
        var version: Int
        var status: RoundingEstimateStatus

        init(code: String, name: String, refills: Int, expiresAt: Int, dosageMg: Double, floorValue: Double, active: Bool, createdAt: Int, version: Int, status: RoundingEstimateStatus) {
            self.code = code
            self.name = name
            self.refills = refills
            self.expiresAt = expiresAt
            self.dosageMg = dosageMg
            self.floorValue = floorValue
            self.active = active
            self.createdAt = createdAt
            self.version = version
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

        func canMoveTo(_ next: RoundingEstimateStatus) -> Bool {
            switch status {
            case .`open`:
                return next == RoundingEstimateStatus.inReview || next == RoundingEstimateStatus.reopened
            case .inReview:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened:
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

        func moveTo(_ next: RoundingEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rounding estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\("rounding estimate") \(code)"
        }

        func weightedValue() -> Double {
            return ((dosageMg + Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> RoundingEstimate {
            return RoundingEstimate(
                code: code,
                name: name,
                refills: refills,
                expiresAt: expiresAt,
                dosageMg: dosageMg,
                floorValue: floorValue,
                active: active,
                createdAt: createdAt,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a rounding estimate in status open.
    static func newRoundingEstimate(_ code: String, name: String) -> RoundingEstimate {
        return RoundingEstimate(
            code: code,
            name: name,
            refills: 0,
            expiresAt: 0,
            dosageMg: 0.0,
            floorValue: 0.0,
            active: false,
            createdAt: 0,
            version: 0,
            status: RoundingEstimateStatus.`open`
        )
    }
}
