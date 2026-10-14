import AcmePlatform
import Foundation

extension Staffing {
    /// Where a overtime template is in its life cycle.
    enum OvertimeTemplateStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A overtime template. Its code is unique within a tenant.
    final class OvertimeTemplate {
        var code: String
        var title: String
        var region: String
        var dosageMg: Double
        var attributes: [String: String]
        var rate: Double
        var status: OvertimeTemplateStatus

        init(code: String, title: String, region: String, dosageMg: Double, attributes: [String: String], rate: Double, status: OvertimeTemplateStatus) {
            self.code = code
            self.title = title
            self.region = region
            self.dosageMg = dosageMg
            self.attributes = attributes
            self.rate = rate
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

        func canMoveTo(_ next: OvertimeTemplateStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == OvertimeTemplateStatus.suspended
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

        func moveTo(_ next: OvertimeTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("overtime template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func projectedTotal() -> Double {
            return ((dosageMg + rate) * 100).rounded() / 100
        }

        func copyValue() -> OvertimeTemplate {
            return OvertimeTemplate(
                code: code,
                title: title,
                region: region,
                dosageMg: dosageMg,
                attributes: attributes,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a overtime template in status draft.
    static func newOvertimeTemplate(_ code: String, title: String) -> OvertimeTemplate {
        return OvertimeTemplate(
            code: code,
            title: title,
            region: "",
            dosageMg: 0.0,
            attributes: [:],
            rate: 0.0,
            status: OvertimeTemplateStatus.draft
        )
    }
}
