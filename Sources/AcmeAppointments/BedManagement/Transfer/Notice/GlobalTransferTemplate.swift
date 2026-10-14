import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a global transfer template is in its life cycle.
    enum GlobalTransferTemplateStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A global transfer template as the transfer team keeps it.
    final class GlobalTransferTemplate {
        var code: String
        var name: String
        var priority: Int
        var source: String
        var ceiling: Double
        var durationMinutes: Int
        var country: String
        var copay: Double
        var status: GlobalTransferTemplateStatus

        init(code: String, name: String, priority: Int, source: String, ceiling: Double, durationMinutes: Int, country: String, copay: Double, status: GlobalTransferTemplateStatus) {
            self.code = code
            self.name = name
            self.priority = priority
            self.source = source
            self.ceiling = ceiling
            self.durationMinutes = durationMinutes
            self.country = country
            self.copay = copay
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: GlobalTransferTemplateStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: GlobalTransferTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global transfer template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func projectedLoad() -> Double {
            return (Double(priority) * ceiling * 100).rounded() / 100
        }

        func copyValue() -> GlobalTransferTemplate {
            return GlobalTransferTemplate(
                code: code,
                name: name,
                priority: priority,
                source: source,
                ceiling: ceiling,
                durationMinutes: durationMinutes,
                country: country,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a global transfer template in status draft.
    static func newGlobalTransferTemplate(_ code: String, name: String) -> GlobalTransferTemplate {
        return GlobalTransferTemplate(
            code: code,
            name: name,
            priority: 0,
            source: "",
            ceiling: 0.0,
            durationMinutes: 0,
            country: "",
            copay: 0.0,
            status: GlobalTransferTemplateStatus.draft
        )
    }
}
