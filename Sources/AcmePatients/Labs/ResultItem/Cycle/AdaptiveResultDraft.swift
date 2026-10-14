import AcmePlatform
import Foundation

extension Labs {
    /// Where a adaptive result draft is in its life cycle.
    enum AdaptiveResultDraftStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a adaptive result draft and its current status.
    final class AdaptiveResultDraft {
        var code: String
        var name: String
        var label: String
        var windowDays: Int
        var copay: Double
        var dosageMg: Double
        var threshold: Double
        var externalRef: String
        var approved: Bool
        var status: AdaptiveResultDraftStatus

        init(code: String, name: String, label: String, windowDays: Int, copay: Double, dosageMg: Double, threshold: Double, externalRef: String, approved: Bool, status: AdaptiveResultDraftStatus) {
            self.code = code
            self.name = name
            self.label = label
            self.windowDays = windowDays
            self.copay = copay
            self.dosageMg = dosageMg
            self.threshold = threshold
            self.externalRef = externalRef
            self.approved = approved
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

        func canMoveTo(_ next: AdaptiveResultDraftStatus) -> Bool {
            switch status {
            case .created:
                return next == AdaptiveResultDraftStatus.validated || next == AdaptiveResultDraftStatus.published
            case .validated:
                return next == AdaptiveResultDraftStatus.published || next == AdaptiveResultDraftStatus.retired
            case .published:
                return next == AdaptiveResultDraftStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveResultDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive result draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("adaptive result draft") \(code)"
        }

        func effectiveVolume() -> Double {
            return ((threshold - copay) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveResultDraft {
            return AdaptiveResultDraft(
                code: code,
                name: name,
                label: label,
                windowDays: windowDays,
                copay: copay,
                dosageMg: dosageMg,
                threshold: threshold,
                externalRef: externalRef,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a adaptive result draft in status created.
    static func newAdaptiveResultDraft(_ code: String, name: String) -> AdaptiveResultDraft {
        return AdaptiveResultDraft(
            code: code,
            name: name,
            label: "",
            windowDays: 0,
            copay: 0.0,
            dosageMg: 0.0,
            threshold: 0.0,
            externalRef: "",
            approved: false,
            status: AdaptiveResultDraftStatus.created
        )
    }
}
