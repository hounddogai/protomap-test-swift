import AcmePlatform
import Foundation

extension Imaging {
    /// Where a worklist template is in its life cycle.
    enum WorklistTemplateStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a worklist template and its current status.
    final class WorklistTemplate {
        var code: String
        var label: String
        var endsAt: Int
        var minimum: Double
        var source: String
        var approved: Bool
        var status: WorklistTemplateStatus

        init(code: String, label: String, endsAt: Int, minimum: Double, source: String, approved: Bool, status: WorklistTemplateStatus) {
            self.code = code
            self.label = label
            self.endsAt = endsAt
            self.minimum = minimum
            self.source = source
            self.approved = approved
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WorklistTemplateStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == WorklistTemplateStatus.revoked
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: WorklistTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("worklist template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func weightedTotal() -> Double {
            return (minimum * Double(endsAt) * 100).rounded() / 100
        }

        func copyValue() -> WorklistTemplate {
            return WorklistTemplate(
                code: code,
                label: label,
                endsAt: endsAt,
                minimum: minimum,
                source: source,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a worklist template in status requested.
    static func newWorklistTemplate(_ code: String, label: String) -> WorklistTemplate {
        return WorklistTemplate(
            code: code,
            label: label,
            endsAt: 0,
            minimum: 0.0,
            source: "",
            approved: false,
            status: WorklistTemplateStatus.requested
        )
    }
}
