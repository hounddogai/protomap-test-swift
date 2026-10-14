import AcmePlatform
import Foundation

extension Staffing {
    /// Where a float pool cycle is in its life cycle.
    enum FloatPoolCycleStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A float pool cycle. Its code is unique within a tenant.
    final class FloatPoolCycle {
        var code: String
        var name: String
        var weight: Double
        var facility: String
        var cost: Double
        var copay: Double
        var tags: [String]
        var attributes: [String: String]
        var refills: Int
        var graceDays: Int
        var status: FloatPoolCycleStatus

        init(code: String, name: String, weight: Double, facility: String, cost: Double, copay: Double, tags: [String], attributes: [String: String], refills: Int, graceDays: Int, status: FloatPoolCycleStatus) {
            self.code = code
            self.name = name
            self.weight = weight
            self.facility = facility
            self.cost = cost
            self.copay = copay
            self.tags = tags
            self.attributes = attributes
            self.refills = refills
            self.graceDays = graceDays
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FloatPoolCycleStatus) -> Bool {
            switch status {
            case .created:
                return next == FloatPoolCycleStatus.validated
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == FloatPoolCycleStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FloatPoolCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("float pool cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
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

        func netVolume() -> Double {
            return ((cost - Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> FloatPoolCycle {
            return FloatPoolCycle(
                code: code,
                name: name,
                weight: weight,
                facility: facility,
                cost: cost,
                copay: copay,
                tags: tags,
                attributes: attributes,
                refills: refills,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a float pool cycle in status created.
    static func newFloatPoolCycle(_ code: String, name: String) -> FloatPoolCycle {
        return FloatPoolCycle(
            code: code,
            name: name,
            weight: 0.0,
            facility: "",
            cost: 0.0,
            copay: 0.0,
            tags: [],
            attributes: [:],
            refills: 0,
            graceDays: 0,
            status: FloatPoolCycleStatus.created
        )
    }
}
