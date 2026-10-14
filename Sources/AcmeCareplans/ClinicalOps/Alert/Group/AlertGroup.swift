import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a alert group is in its life cycle.
    enum AlertGroupStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A alert group as the alert team keeps it.
    final class AlertGroup {
        var code: String
        var label: String
        var payer: String
        var source: String
        var ceiling: Double
        var locale: String
        var encounterID: String
        var active: Bool
        var status: AlertGroupStatus

        init(code: String, label: String, payer: String, source: String, ceiling: Double, locale: String, encounterID: String, active: Bool, status: AlertGroupStatus) {
            self.code = code
            self.label = label
            self.payer = payer
            self.source = source
            self.ceiling = ceiling
            self.locale = locale
            self.encounterID = encounterID
            self.active = active
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AlertGroupStatus) -> Bool {
            switch status {
            case .new:
                return next == AlertGroupStatus.failed
            case .queued:
                return next == AlertGroupStatus.failed
            case .running:
                return next == AlertGroupStatus.done || next == AlertGroupStatus.failed
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: AlertGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("alert group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func measuredValue() -> Double {
            return ceiling
        }

        func copyValue() -> AlertGroup {
            return AlertGroup(
                code: code,
                label: label,
                payer: payer,
                source: source,
                ceiling: ceiling,
                locale: locale,
                encounterID: encounterID,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a alert group in status new.
    static func newAlertGroup(_ code: String, label: String) -> AlertGroup {
        return AlertGroup(
            code: code,
            label: label,
            payer: "",
            source: "",
            ceiling: 0.0,
            locale: "",
            encounterID: "",
            active: false,
            status: AlertGroupStatus.new
        )
    }
}
