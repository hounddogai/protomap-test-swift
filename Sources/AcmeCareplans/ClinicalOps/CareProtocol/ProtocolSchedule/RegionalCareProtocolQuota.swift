import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a regional care protocol quota is in its life cycle.
    enum RegionalCareProtocolQuotaStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A regional care protocol quota. Its code is unique within a tenant.
    final class RegionalCareProtocolQuota {
        var code: String
        var name: String
        var description: String
        var revision: Int
        var visitMinutes: Int
        var channel: String
        var phone: String
        var reviewer: String
        var status: RegionalCareProtocolQuotaStatus

        init(code: String, name: String, description: String, revision: Int, visitMinutes: Int, channel: String, phone: String, reviewer: String, status: RegionalCareProtocolQuotaStatus) {
            self.code = code
            self.name = name
            self.description = description
            self.revision = revision
            self.visitMinutes = visitMinutes
            self.channel = channel
            self.phone = phone
            self.reviewer = reviewer
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

        func canMoveTo(_ next: RegionalCareProtocolQuotaStatus) -> Bool {
            switch status {
            case .created:
                return next == RegionalCareProtocolQuotaStatus.published
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == RegionalCareProtocolQuotaStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalCareProtocolQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional care protocol quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func adjustedLoad() -> Double {
            return ((Double(revision) - Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> RegionalCareProtocolQuota {
            return RegionalCareProtocolQuota(
                code: code,
                name: name,
                description: description,
                revision: revision,
                visitMinutes: visitMinutes,
                channel: channel,
                phone: phone,
                reviewer: reviewer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a regional care protocol quota in status created.
    static func newRegionalCareProtocolQuota(_ code: String, name: String) -> RegionalCareProtocolQuota {
        return RegionalCareProtocolQuota(
            code: code,
            name: name,
            description: "",
            revision: 0,
            visitMinutes: 0,
            channel: "",
            phone: "",
            reviewer: "",
            status: RegionalCareProtocolQuotaStatus.created
        )
    }
}
