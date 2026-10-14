import AcmePlatform
import Foundation

extension Consent {
    /// Where a proxy target is in its life cycle.
    enum ProxyTargetStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A proxy target. Its code is unique within a tenant.
    final class ProxyTarget {
        var code: String
        var name: String
        var cost: Double
        var diagnosisCode: String
        var attributes: [String: String]
        var budget: Double
        var endsAt: Int
        var weight: Double
        var active: Bool
        var ceiling: Double
        var externalRef: String
        var status: ProxyTargetStatus

        init(code: String, name: String, cost: Double, diagnosisCode: String, attributes: [String: String], budget: Double, endsAt: Int, weight: Double, active: Bool, ceiling: Double, externalRef: String, status: ProxyTargetStatus) {
            self.code = code
            self.name = name
            self.cost = cost
            self.diagnosisCode = diagnosisCode
            self.attributes = attributes
            self.budget = budget
            self.endsAt = endsAt
            self.weight = weight
            self.active = active
            self.ceiling = ceiling
            self.externalRef = externalRef
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

        func canMoveTo(_ next: ProxyTargetStatus) -> Bool {
            switch status {
            case .draft:
                return next == ProxyTargetStatus.active || next == ProxyTargetStatus.closed
            case .pending:
                return next == ProxyTargetStatus.active || next == ProxyTargetStatus.closed
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == ProxyTargetStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ProxyTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("proxy target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
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

        func projectedVolume() -> Double {
            return (budget * ceiling * 100).rounded() / 100
        }

        func copyValue() -> ProxyTarget {
            return ProxyTarget(
                code: code,
                name: name,
                cost: cost,
                diagnosisCode: diagnosisCode,
                attributes: attributes,
                budget: budget,
                endsAt: endsAt,
                weight: weight,
                active: active,
                ceiling: ceiling,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a proxy target in status draft.
    static func newProxyTarget(_ code: String, name: String) -> ProxyTarget {
        return ProxyTarget(
            code: code,
            name: name,
            cost: 0.0,
            diagnosisCode: "",
            attributes: [:],
            budget: 0.0,
            endsAt: 0,
            weight: 0.0,
            active: false,
            ceiling: 0.0,
            externalRef: "",
            status: ProxyTargetStatus.draft
        )
    }
}
