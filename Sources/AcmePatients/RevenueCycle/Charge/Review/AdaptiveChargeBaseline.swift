import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a adaptive charge baseline is in its life cycle.
    enum AdaptiveChargeBaselineStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a adaptive charge baseline and its current status.
    final class AdaptiveChargeBaseline {
        var code: String
        var name: String
        var clinicianID: String
        var description: String
        var allergy: String
        var quantity: Int
        var status: AdaptiveChargeBaselineStatus

        init(code: String, name: String, clinicianID: String, description: String, allergy: String, quantity: Int, status: AdaptiveChargeBaselineStatus) {
            self.code = code
            self.name = name
            self.clinicianID = clinicianID
            self.description = description
            self.allergy = allergy
            self.quantity = quantity
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

        func canMoveTo(_ next: AdaptiveChargeBaselineStatus) -> Bool {
            switch status {
            case .created:
                return next == AdaptiveChargeBaselineStatus.validated
            case .validated:
                return next == AdaptiveChargeBaselineStatus.published || next == AdaptiveChargeBaselineStatus.retired
            case .published:
                return next == AdaptiveChargeBaselineStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveChargeBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive charge baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("adaptive charge baseline") \(code)"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> AdaptiveChargeBaseline {
            return AdaptiveChargeBaseline(
                code: code,
                name: name,
                clinicianID: clinicianID,
                description: description,
                allergy: allergy,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a adaptive charge baseline in status created.
    static func newAdaptiveChargeBaseline(_ code: String, name: String) -> AdaptiveChargeBaseline {
        return AdaptiveChargeBaseline(
            code: code,
            name: name,
            clinicianID: "",
            description: "",
            allergy: "",
            quantity: 0,
            status: AdaptiveChargeBaselineStatus.created
        )
    }
}
