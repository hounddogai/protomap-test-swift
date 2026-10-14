import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a remittance template is in its life cycle.
    enum RemittanceTemplateStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A remittance template as the remittance team keeps it.
    final class RemittanceTemplate {
        var code: String
        var title: String
        var bed: String
        var amount: Double
        var maximum: Double
        var status: RemittanceTemplateStatus

        init(code: String, title: String, bed: String, amount: Double, maximum: Double, status: RemittanceTemplateStatus) {
            self.code = code
            self.title = title
            self.bed = bed
            self.amount = amount
            self.maximum = maximum
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

        func canMoveTo(_ next: RemittanceTemplateStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == RemittanceTemplateStatus.failed
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == RemittanceTemplateStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RemittanceTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("remittance template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func projectedVolume() -> Double {
            return ((maximum - amount) * 100).rounded() / 100
        }

        func copyValue() -> RemittanceTemplate {
            return RemittanceTemplate(
                code: code,
                title: title,
                bed: bed,
                amount: amount,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a remittance template in status new.
    static func newRemittanceTemplate(_ code: String, title: String) -> RemittanceTemplate {
        return RemittanceTemplate(
            code: code,
            title: title,
            bed: "",
            amount: 0.0,
            maximum: 0.0,
            status: RemittanceTemplateStatus.new
        )
    }
}
