import AcmePlatform
import Foundation

extension Staffing {
    /// Where a strict overtime override is in its life cycle.
    enum StrictOvertimeOverrideStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One strict overtime override, with what the planners need to act on it.
    final class StrictOvertimeOverride {
        var code: String
        var title: String
        var quantity: Int
        var name: String
        var visitMinutes: Int
        var approved: Bool
        var procedureCode: String
        var attributes: [String: String]
        var cost: Double
        var active: Bool
        var durationMinutes: Int
        var status: StrictOvertimeOverrideStatus

        init(code: String, title: String, quantity: Int, name: String, visitMinutes: Int, approved: Bool, procedureCode: String, attributes: [String: String], cost: Double, active: Bool, durationMinutes: Int, status: StrictOvertimeOverrideStatus) {
            self.code = code
            self.title = title
            self.quantity = quantity
            self.name = name
            self.visitMinutes = visitMinutes
            self.approved = approved
            self.procedureCode = procedureCode
            self.attributes = attributes
            self.cost = cost
            self.active = active
            self.durationMinutes = durationMinutes
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

        func canMoveTo(_ next: StrictOvertimeOverrideStatus) -> Bool {
            switch status {
            case .requested:
                return next == StrictOvertimeOverrideStatus.expired
            case .granted:
                return next == StrictOvertimeOverrideStatus.expired
            case .revoked:
                return next == StrictOvertimeOverrideStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictOvertimeOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict overtime override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
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

        func adjustedValue() -> Double {
            return ((Double(visitMinutes) + cost) * 100).rounded() / 100
        }

        func copyValue() -> StrictOvertimeOverride {
            return StrictOvertimeOverride(
                code: code,
                title: title,
                quantity: quantity,
                name: name,
                visitMinutes: visitMinutes,
                approved: approved,
                procedureCode: procedureCode,
                attributes: attributes,
                cost: cost,
                active: active,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a strict overtime override in status requested.
    static func newStrictOvertimeOverride(_ code: String, title: String) -> StrictOvertimeOverride {
        return StrictOvertimeOverride(
            code: code,
            title: title,
            quantity: 0,
            name: "",
            visitMinutes: 0,
            approved: false,
            procedureCode: "",
            attributes: [:],
            cost: 0.0,
            active: false,
            durationMinutes: 0,
            status: StrictOvertimeOverrideStatus.requested
        )
    }
}
