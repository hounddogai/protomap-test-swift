import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a primary remittance variance is in its life cycle.
    enum PrimaryRemittanceVarianceStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a primary remittance variance and its current status.
    final class PrimaryRemittanceVariance {
        var code: String
        var title: String
        var limit: Int
        var unit: String
        var ceiling: Double
        var cost: Double
        var tags: [String]
        var weight: Double
        var ward: String
        var refills: Int
        var status: PrimaryRemittanceVarianceStatus

        init(code: String, title: String, limit: Int, unit: String, ceiling: Double, cost: Double, tags: [String], weight: Double, ward: String, refills: Int, status: PrimaryRemittanceVarianceStatus) {
            self.code = code
            self.title = title
            self.limit = limit
            self.unit = unit
            self.ceiling = ceiling
            self.cost = cost
            self.tags = tags
            self.weight = weight
            self.ward = ward
            self.refills = refills
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

        func canMoveTo(_ next: PrimaryRemittanceVarianceStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .archived:
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

        func moveTo(_ next: PrimaryRemittanceVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary remittance variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("primary remittance variance") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveValue() -> Double {
            return ((Double(refills) - weight) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryRemittanceVariance {
            return PrimaryRemittanceVariance(
                code: code,
                title: title,
                limit: limit,
                unit: unit,
                ceiling: ceiling,
                cost: cost,
                tags: tags,
                weight: weight,
                ward: ward,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a primary remittance variance in status open.
    static func newPrimaryRemittanceVariance(_ code: String, title: String) -> PrimaryRemittanceVariance {
        return PrimaryRemittanceVariance(
            code: code,
            title: title,
            limit: 0,
            unit: "",
            ceiling: 0.0,
            cost: 0.0,
            tags: [],
            weight: 0.0,
            ward: "",
            refills: 0,
            status: PrimaryRemittanceVarianceStatus.`open`
        )
    }
}
