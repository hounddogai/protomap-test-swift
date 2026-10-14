import AcmePlatform
import Foundation

extension Referrals {
    /// Where a closure plan is in its life cycle.
    enum ClosurePlanStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A closure plan as the closure team keeps it.
    final class ClosurePlan {
        var code: String
        var name: String
        var tags: [String]
        var unit: String
        var patientRef: String
        var minimum: Double
        var amount: Double
        var status: ClosurePlanStatus

        init(code: String, name: String, tags: [String], unit: String, patientRef: String, minimum: Double, amount: Double, status: ClosurePlanStatus) {
            self.code = code
            self.name = name
            self.tags = tags
            self.unit = unit
            self.patientRef = patientRef
            self.minimum = minimum
            self.amount = amount
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

        func canMoveTo(_ next: ClosurePlanStatus) -> Bool {
            switch status {
            case .requested:
                return next == ClosurePlanStatus.granted || next == ClosurePlanStatus.expired
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == ClosurePlanStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ClosurePlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("closure plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func netValue() -> Double {
            return ((minimum + amount) * 100).rounded() / 100
        }

        func copyValue() -> ClosurePlan {
            return ClosurePlan(
                code: code,
                name: name,
                tags: tags,
                unit: unit,
                patientRef: patientRef,
                minimum: minimum,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a closure plan in status requested.
    static func newClosurePlan(_ code: String, name: String) -> ClosurePlan {
        return ClosurePlan(
            code: code,
            name: name,
            tags: [],
            unit: "",
            patientRef: "",
            minimum: 0.0,
            amount: 0.0,
            status: ClosurePlanStatus.requested
        )
    }
}
