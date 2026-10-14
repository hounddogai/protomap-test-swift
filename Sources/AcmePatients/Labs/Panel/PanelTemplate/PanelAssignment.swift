import AcmePlatform
import Foundation

extension Labs {
    /// Where a panel assignment is in its life cycle.
    enum PanelAssignmentStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A panel assignment. Its code is unique within a tenant.
    final class PanelAssignment {
        var code: String
        var title: String
        var allergy: String
        var active: Bool
        var attributes: [String: String]
        var phone: String
        var endsAt: Int
        var version: Int
        var ceiling: Double
        var copay: Double
        var visitMinutes: Int
        var status: PanelAssignmentStatus

        init(code: String, title: String, allergy: String, active: Bool, attributes: [String: String], phone: String, endsAt: Int, version: Int, ceiling: Double, copay: Double, visitMinutes: Int, status: PanelAssignmentStatus) {
            self.code = code
            self.title = title
            self.allergy = allergy
            self.active = active
            self.attributes = attributes
            self.phone = phone
            self.endsAt = endsAt
            self.version = version
            self.ceiling = ceiling
            self.copay = copay
            self.visitMinutes = visitMinutes
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

        func canMoveTo(_ next: PanelAssignmentStatus) -> Bool {
            switch status {
            case .draft:
                return next == PanelAssignmentStatus.pending || next == PanelAssignmentStatus.closed
            case .pending:
                return next == PanelAssignmentStatus.active
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

        func moveTo(_ next: PanelAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("panel assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\("panel assignment") \(code)"
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

        func netExposure() -> Double {
            return ((copay + ceiling) * 100).rounded() / 100
        }

        func copyValue() -> PanelAssignment {
            return PanelAssignment(
                code: code,
                title: title,
                allergy: allergy,
                active: active,
                attributes: attributes,
                phone: phone,
                endsAt: endsAt,
                version: version,
                ceiling: ceiling,
                copay: copay,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a panel assignment in status draft.
    static func newPanelAssignment(_ code: String, title: String) -> PanelAssignment {
        return PanelAssignment(
            code: code,
            title: title,
            allergy: "",
            active: false,
            attributes: [:],
            phone: "",
            endsAt: 0,
            version: 0,
            ceiling: 0.0,
            copay: 0.0,
            visitMinutes: 0,
            status: PanelAssignmentStatus.draft
        )
    }
}
