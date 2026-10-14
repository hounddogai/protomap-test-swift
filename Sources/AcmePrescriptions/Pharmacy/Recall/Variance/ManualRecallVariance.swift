import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a manual recall variance is in its life cycle.
    enum ManualRecallVarianceStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A manual recall variance. Its code is unique within a tenant.
    final class ManualRecallVariance {
        var code: String
        var name: String
        var allergy: String
        var refills: Int
        var currency: String
        var pinned: Bool
        var endsAt: Int
        var budget: Double
        var active: Bool
        var summary: String
        var status: ManualRecallVarianceStatus

        init(code: String, name: String, allergy: String, refills: Int, currency: String, pinned: Bool, endsAt: Int, budget: Double, active: Bool, summary: String, status: ManualRecallVarianceStatus) {
            self.code = code
            self.name = name
            self.allergy = allergy
            self.refills = refills
            self.currency = currency
            self.pinned = pinned
            self.endsAt = endsAt
            self.budget = budget
            self.active = active
            self.summary = summary
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

        func canMoveTo(_ next: ManualRecallVarianceStatus) -> Bool {
            switch status {
            case .created:
                return next == ManualRecallVarianceStatus.published
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: ManualRecallVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual recall variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("manual recall variance") \(code)"
        }

        func weightedTotal() -> Double {
            return ((Double(endsAt) - budget) * 100).rounded() / 100
        }

        func copyValue() -> ManualRecallVariance {
            return ManualRecallVariance(
                code: code,
                name: name,
                allergy: allergy,
                refills: refills,
                currency: currency,
                pinned: pinned,
                endsAt: endsAt,
                budget: budget,
                active: active,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a manual recall variance in status created.
    static func newManualRecallVariance(_ code: String, name: String) -> ManualRecallVariance {
        return ManualRecallVariance(
            code: code,
            name: name,
            allergy: "",
            refills: 0,
            currency: "",
            pinned: false,
            endsAt: 0,
            budget: 0.0,
            active: false,
            summary: "",
            status: ManualRecallVarianceStatus.created
        )
    }
}
