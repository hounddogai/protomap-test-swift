import AcmePlatform
import Foundation

extension Referrals {
    /// Where a weighted eligibility bundle is in its life cycle.
    enum WeightedEligibilityBundleStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A weighted eligibility bundle. Its code is unique within a tenant.
    final class WeightedEligibilityBundle {
        var code: String
        var name: String
        var batchSize: Int
        var payer: String
        var pinned: Bool
        var country: String
        var visible: Bool
        var status: WeightedEligibilityBundleStatus

        init(code: String, name: String, batchSize: Int, payer: String, pinned: Bool, country: String, visible: Bool, status: WeightedEligibilityBundleStatus) {
            self.code = code
            self.name = name
            self.batchSize = batchSize
            self.payer = payer
            self.pinned = pinned
            self.country = country
            self.visible = visible
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

        func canMoveTo(_ next: WeightedEligibilityBundleStatus) -> Bool {
            switch status {
            case .created:
                return next == WeightedEligibilityBundleStatus.validated
            case .validated:
                return next == WeightedEligibilityBundleStatus.published || next == WeightedEligibilityBundleStatus.retired
            case .published:
                return next == WeightedEligibilityBundleStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedEligibilityBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted eligibility bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func measuredValue() -> Double {
            return Double(batchSize)
        }

        func copyValue() -> WeightedEligibilityBundle {
            return WeightedEligibilityBundle(
                code: code,
                name: name,
                batchSize: batchSize,
                payer: payer,
                pinned: pinned,
                country: country,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a weighted eligibility bundle in status created.
    static func newWeightedEligibilityBundle(_ code: String, name: String) -> WeightedEligibilityBundle {
        return WeightedEligibilityBundle(
            code: code,
            name: name,
            batchSize: 0,
            payer: "",
            pinned: false,
            country: "",
            visible: false,
            status: WeightedEligibilityBundleStatus.created
        )
    }
}
