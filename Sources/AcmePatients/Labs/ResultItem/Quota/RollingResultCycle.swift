import AcmePlatform
import Foundation

extension Labs {
    /// Where a rolling result cycle is in its life cycle.
    enum RollingResultCycleStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A rolling result cycle as the result team keeps it.
    final class RollingResultCycle {
        var code: String
        var title: String
        var tags: [String]
        var ward: String
        var createdAt: Int
        var copay: Double
        var cost: Double
        var weight: Double
        var version: Int
        var description: String
        var refills: Int
        var status: RollingResultCycleStatus

        init(code: String, title: String, tags: [String], ward: String, createdAt: Int, copay: Double, cost: Double, weight: Double, version: Int, description: String, refills: Int, status: RollingResultCycleStatus) {
            self.code = code
            self.title = title
            self.tags = tags
            self.ward = ward
            self.createdAt = createdAt
            self.copay = copay
            self.cost = cost
            self.weight = weight
            self.version = version
            self.description = description
            self.refills = refills
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RollingResultCycleStatus) -> Bool {
            switch status {
            case .idle:
                return next == RollingResultCycleStatus.warming || next == RollingResultCycleStatus.draining
            case .warming:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == RollingResultCycleStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingResultCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling result cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\("rolling result cycle") \(code)"
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
            return (Double(version) * copay * 100).rounded() / 100
        }

        func copyValue() -> RollingResultCycle {
            return RollingResultCycle(
                code: code,
                title: title,
                tags: tags,
                ward: ward,
                createdAt: createdAt,
                copay: copay,
                cost: cost,
                weight: weight,
                version: version,
                description: description,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a rolling result cycle in status idle.
    static func newRollingResultCycle(_ code: String, title: String) -> RollingResultCycle {
        return RollingResultCycle(
            code: code,
            title: title,
            tags: [],
            ward: "",
            createdAt: 0,
            copay: 0.0,
            cost: 0.0,
            weight: 0.0,
            version: 0,
            description: "",
            refills: 0,
            status: RollingResultCycleStatus.idle
        )
    }
}
