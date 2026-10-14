import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a alert template is in its life cycle.
    enum AlertTemplateStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A alert template. Its code is unique within a tenant.
    final class AlertTemplate {
        var code: String
        var name: String
        var refills: Int
        var priority: Int
        var cost: Double
        var description: String
        var batchSize: Int
        var active: Bool
        var locale: String
        var sequence: Int
        var status: AlertTemplateStatus

        init(code: String, name: String, refills: Int, priority: Int, cost: Double, description: String, batchSize: Int, active: Bool, locale: String, sequence: Int, status: AlertTemplateStatus) {
            self.code = code
            self.name = name
            self.refills = refills
            self.priority = priority
            self.cost = cost
            self.description = description
            self.batchSize = batchSize
            self.active = active
            self.locale = locale
            self.sequence = sequence
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

        func canMoveTo(_ next: AlertTemplateStatus) -> Bool {
            switch status {
            case .new:
                return next == AlertTemplateStatus.done || next == AlertTemplateStatus.failed
            case .queued:
                return next == AlertTemplateStatus.running || next == AlertTemplateStatus.failed
            case .running:
                return next == AlertTemplateStatus.done || next == AlertTemplateStatus.failed
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

        func moveTo(_ next: AlertTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("alert template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func weightedVolume() -> Double {
            return (Double(priority) * cost * 100).rounded() / 100
        }

        func copyValue() -> AlertTemplate {
            return AlertTemplate(
                code: code,
                name: name,
                refills: refills,
                priority: priority,
                cost: cost,
                description: description,
                batchSize: batchSize,
                active: active,
                locale: locale,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a alert template in status new.
    static func newAlertTemplate(_ code: String, name: String) -> AlertTemplate {
        return AlertTemplate(
            code: code,
            name: name,
            refills: 0,
            priority: 0,
            cost: 0.0,
            description: "",
            batchSize: 0,
            active: false,
            locale: "",
            sequence: 0,
            status: AlertTemplateStatus.new
        )
    }
}
