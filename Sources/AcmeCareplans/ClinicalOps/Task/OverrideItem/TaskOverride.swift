import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a task override is in its life cycle.
    enum TaskOverrideStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A task override. Its code is unique within a tenant.
    final class TaskOverride {
        var code: String
        var title: String
        var dosageMg: Double
        var quantity: Int
        var revision: Int
        var locale: String
        var name: String
        var discount: Double
        var ceiling: Double
        var payer: String
        var status: TaskOverrideStatus

        init(code: String, title: String, dosageMg: Double, quantity: Int, revision: Int, locale: String, name: String, discount: Double, ceiling: Double, payer: String, status: TaskOverrideStatus) {
            self.code = code
            self.title = title
            self.dosageMg = dosageMg
            self.quantity = quantity
            self.revision = revision
            self.locale = locale
            self.name = name
            self.discount = discount
            self.ceiling = ceiling
            self.payer = payer
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

        func canMoveTo(_ next: TaskOverrideStatus) -> Bool {
            switch status {
            case .new:
                return next == TaskOverrideStatus.queued
            case .queued:
                return next == TaskOverrideStatus.done
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: TaskOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("task override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func adjustedTotal() -> Double {
            return ((Double(revision) - Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> TaskOverride {
            return TaskOverride(
                code: code,
                title: title,
                dosageMg: dosageMg,
                quantity: quantity,
                revision: revision,
                locale: locale,
                name: name,
                discount: discount,
                ceiling: ceiling,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a task override in status new.
    static func newTaskOverride(_ code: String, title: String) -> TaskOverride {
        return TaskOverride(
            code: code,
            title: title,
            dosageMg: 0.0,
            quantity: 0,
            revision: 0,
            locale: "",
            name: "",
            discount: 0.0,
            ceiling: 0.0,
            payer: "",
            status: TaskOverrideStatus.new
        )
    }
}
