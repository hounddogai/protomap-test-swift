import AcmePlatform
import Foundation

extension Staffing {
    /// Where a capped skill mix estimate is in its life cycle.
    enum CappedSkillMixEstimateStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a capped skill mix estimate and its current status.
    final class CappedSkillMixEstimate {
        var code: String
        var name: String
        var country: String
        var refills: Int
        var maximum: Double
        var rate: Double
        var ceiling: Double
        var status: CappedSkillMixEstimateStatus

        init(code: String, name: String, country: String, refills: Int, maximum: Double, rate: Double, ceiling: Double, status: CappedSkillMixEstimateStatus) {
            self.code = code
            self.name = name
            self.country = country
            self.refills = refills
            self.maximum = maximum
            self.rate = rate
            self.ceiling = ceiling
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

        func canMoveTo(_ next: CappedSkillMixEstimateStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == CappedSkillMixEstimateStatus.active || next == CappedSkillMixEstimateStatus.suspended
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: CappedSkillMixEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped skill mix estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("capped skill mix estimate") \(code)"
        }

        func adjustedTotal() -> Double {
            return ((maximum - ceiling) * 100).rounded() / 100
        }

        func copyValue() -> CappedSkillMixEstimate {
            return CappedSkillMixEstimate(
                code: code,
                name: name,
                country: country,
                refills: refills,
                maximum: maximum,
                rate: rate,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a capped skill mix estimate in status draft.
    static func newCappedSkillMixEstimate(_ code: String, name: String) -> CappedSkillMixEstimate {
        return CappedSkillMixEstimate(
            code: code,
            name: name,
            country: "",
            refills: 0,
            maximum: 0.0,
            rate: 0.0,
            ceiling: 0.0,
            status: CappedSkillMixEstimateStatus.draft
        )
    }
}
