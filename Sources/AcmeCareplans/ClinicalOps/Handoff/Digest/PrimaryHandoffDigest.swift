import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a primary handoff digest is in its life cycle.
    enum PrimaryHandoffDigestStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a primary handoff digest and its current status.
    final class PrimaryHandoffDigest {
        var code: String
        var title: String
        var visitMinutes: Int
        var channel: String
        var dosageMg: Double
        var capacity: Int
        var createdAt: Int
        var ward: String
        var status: PrimaryHandoffDigestStatus

        init(code: String, title: String, visitMinutes: Int, channel: String, dosageMg: Double, capacity: Int, createdAt: Int, ward: String, status: PrimaryHandoffDigestStatus) {
            self.code = code
            self.title = title
            self.visitMinutes = visitMinutes
            self.channel = channel
            self.dosageMg = dosageMg
            self.capacity = capacity
            self.createdAt = createdAt
            self.ward = ward
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

        func canMoveTo(_ next: PrimaryHandoffDigestStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == PrimaryHandoffDigestStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryHandoffDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary handoff digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("primary handoff digest") \(code)"
        }

        func netTotal() -> Double {
            return (dosageMg * Double(visitMinutes) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryHandoffDigest {
            return PrimaryHandoffDigest(
                code: code,
                title: title,
                visitMinutes: visitMinutes,
                channel: channel,
                dosageMg: dosageMg,
                capacity: capacity,
                createdAt: createdAt,
                ward: ward,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a primary handoff digest in status created.
    static func newPrimaryHandoffDigest(_ code: String, title: String) -> PrimaryHandoffDigest {
        return PrimaryHandoffDigest(
            code: code,
            title: title,
            visitMinutes: 0,
            channel: "",
            dosageMg: 0.0,
            capacity: 0,
            createdAt: 0,
            ward: "",
            status: PrimaryHandoffDigestStatus.created
        )
    }
}
