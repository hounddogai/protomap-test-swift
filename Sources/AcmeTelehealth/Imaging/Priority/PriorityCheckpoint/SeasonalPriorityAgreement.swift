import AcmePlatform
import Foundation

extension Imaging {
    /// Where a seasonal priority agreement is in its life cycle.
    enum SeasonalPriorityAgreementStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a seasonal priority agreement and its current status.
    final class SeasonalPriorityAgreement {
        var code: String
        var name: String
        var ratio: Double
        var copay: Double
        var label: String
        var status: SeasonalPriorityAgreementStatus

        init(code: String, name: String, ratio: Double, copay: Double, label: String, status: SeasonalPriorityAgreementStatus) {
            self.code = code
            self.name = name
            self.ratio = ratio
            self.copay = copay
            self.label = label
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

        func canMoveTo(_ next: SeasonalPriorityAgreementStatus) -> Bool {
            switch status {
            case .created:
                return next == SeasonalPriorityAgreementStatus.published || next == SeasonalPriorityAgreementStatus.retired
            case .validated:
                return next == SeasonalPriorityAgreementStatus.published || next == SeasonalPriorityAgreementStatus.retired
            case .published:
                return next == SeasonalPriorityAgreementStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalPriorityAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal priority agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(name)"
        }

        func effectiveLoad() -> Double {
            return ((ratio - copay) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalPriorityAgreement {
            return SeasonalPriorityAgreement(
                code: code,
                name: name,
                ratio: ratio,
                copay: copay,
                label: label,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a seasonal priority agreement in status created.
    static func newSeasonalPriorityAgreement(_ code: String, name: String) -> SeasonalPriorityAgreement {
        return SeasonalPriorityAgreement(
            code: code,
            name: name,
            ratio: 0.0,
            copay: 0.0,
            label: "",
            status: SeasonalPriorityAgreementStatus.created
        )
    }
}
