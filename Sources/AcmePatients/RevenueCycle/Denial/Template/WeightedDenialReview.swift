import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a weighted denial review is in its life cycle.
    enum WeightedDenialReviewStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A weighted denial review. Its code is unique within a tenant.
    final class WeightedDenialReview {
        var code: String
        var name: String
        var allergy: String
        var windowDays: Int
        var currency: String
        var visible: Bool
        var attributes: [String: String]
        var diagnosisCode: String
        var cost: Double
        var status: WeightedDenialReviewStatus

        init(code: String, name: String, allergy: String, windowDays: Int, currency: String, visible: Bool, attributes: [String: String], diagnosisCode: String, cost: Double, status: WeightedDenialReviewStatus) {
            self.code = code
            self.name = name
            self.allergy = allergy
            self.windowDays = windowDays
            self.currency = currency
            self.visible = visible
            self.attributes = attributes
            self.diagnosisCode = diagnosisCode
            self.cost = cost
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WeightedDenialReviewStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == WeightedDenialReviewStatus.revoked || next == WeightedDenialReviewStatus.expired
            case .revoked:
                return next == WeightedDenialReviewStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedDenialReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted denial review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("weighted denial review") \(code)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func effectiveTotal() -> Double {
            return ((cost + Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> WeightedDenialReview {
            return WeightedDenialReview(
                code: code,
                name: name,
                allergy: allergy,
                windowDays: windowDays,
                currency: currency,
                visible: visible,
                attributes: attributes,
                diagnosisCode: diagnosisCode,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a weighted denial review in status requested.
    static func newWeightedDenialReview(_ code: String, name: String) -> WeightedDenialReview {
        return WeightedDenialReview(
            code: code,
            name: name,
            allergy: "",
            windowDays: 0,
            currency: "",
            visible: false,
            attributes: [:],
            diagnosisCode: "",
            cost: 0.0,
            status: WeightedDenialReviewStatus.requested
        )
    }
}
