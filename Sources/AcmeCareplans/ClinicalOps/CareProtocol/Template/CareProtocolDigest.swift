import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a care protocol digest is in its life cycle.
    enum CareProtocolDigestStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A care protocol digest. Its code is unique within a tenant.
    final class CareProtocolDigest {
        var code: String
        var name: String
        var durationMinutes: Int
        var source: String
        var budget: Double
        var createdAt: Int
        var status: CareProtocolDigestStatus

        init(code: String, name: String, durationMinutes: Int, source: String, budget: Double, createdAt: Int, status: CareProtocolDigestStatus) {
            self.code = code
            self.name = name
            self.durationMinutes = durationMinutes
            self.source = source
            self.budget = budget
            self.createdAt = createdAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CareProtocolDigestStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == CareProtocolDigestStatus.completed || next == CareProtocolDigestStatus.cancelled
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == CareProtocolDigestStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareProtocolDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func netLoad() -> Double {
            return (Double(createdAt) * budget * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolDigest {
            return CareProtocolDigest(
                code: code,
                name: name,
                durationMinutes: durationMinutes,
                source: source,
                budget: budget,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a care protocol digest in status planned.
    static func newCareProtocolDigest(_ code: String, name: String) -> CareProtocolDigest {
        return CareProtocolDigest(
            code: code,
            name: name,
            durationMinutes: 0,
            source: "",
            budget: 0.0,
            createdAt: 0,
            status: CareProtocolDigestStatus.planned
        )
    }
}
