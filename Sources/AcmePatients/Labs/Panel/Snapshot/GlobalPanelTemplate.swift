import AcmePlatform
import Foundation

extension Labs {
    /// Where a global panel template is in its life cycle.
    enum GlobalPanelTemplateStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A global panel template as the panel team keeps it.
    final class GlobalPanelTemplate {
        var code: String
        var label: String
        var discount: Double
        var channel: String
        var retries: Int
        var sequence: Int
        var graceDays: Int
        var weight: Double
        var status: GlobalPanelTemplateStatus

        init(code: String, label: String, discount: Double, channel: String, retries: Int, sequence: Int, graceDays: Int, weight: Double, status: GlobalPanelTemplateStatus) {
            self.code = code
            self.label = label
            self.discount = discount
            self.channel = channel
            self.retries = retries
            self.sequence = sequence
            self.graceDays = graceDays
            self.weight = weight
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

        func canMoveTo(_ next: GlobalPanelTemplateStatus) -> Bool {
            switch status {
            case .new:
                return next == GlobalPanelTemplateStatus.running
            case .queued:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == GlobalPanelTemplateStatus.failed
            case .done:
                return next == GlobalPanelTemplateStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalPanelTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global panel template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("global panel template") \(code)"
        }

        func weightedExposure() -> Double {
            return (Double(graceDays) * discount * 100).rounded() / 100
        }

        func copyValue() -> GlobalPanelTemplate {
            return GlobalPanelTemplate(
                code: code,
                label: label,
                discount: discount,
                channel: channel,
                retries: retries,
                sequence: sequence,
                graceDays: graceDays,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a global panel template in status new.
    static func newGlobalPanelTemplate(_ code: String, label: String) -> GlobalPanelTemplate {
        return GlobalPanelTemplate(
            code: code,
            label: label,
            discount: 0.0,
            channel: "",
            retries: 0,
            sequence: 0,
            graceDays: 0,
            weight: 0.0,
            status: GlobalPanelTemplateStatus.new
        )
    }
}
