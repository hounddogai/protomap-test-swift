import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a default census agreement is in its life cycle.
    enum DefaultCensusAgreementStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A default census agreement as the census team keeps it.
    final class DefaultCensusAgreement {
        var code: String
        var title: String
        var externalRef: String
        var limit: Int
        var channel: String
        var contactEmail: String
        var batchSize: Int
        var updatedAt: Int
        var refills: Int
        var name: String
        var status: DefaultCensusAgreementStatus

        init(code: String, title: String, externalRef: String, limit: Int, channel: String, contactEmail: String, batchSize: Int, updatedAt: Int, refills: Int, name: String, status: DefaultCensusAgreementStatus) {
            self.code = code
            self.title = title
            self.externalRef = externalRef
            self.limit = limit
            self.channel = channel
            self.contactEmail = contactEmail
            self.batchSize = batchSize
            self.updatedAt = updatedAt
            self.refills = refills
            self.name = name
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

        func canMoveTo(_ next: DefaultCensusAgreementStatus) -> Bool {
            switch status {
            case .created:
                return next == DefaultCensusAgreementStatus.validated || next == DefaultCensusAgreementStatus.published
            case .validated:
                return next == DefaultCensusAgreementStatus.published
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: DefaultCensusAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default census agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func projectedVolume() -> Double {
            return (Double(batchSize) * Double(updatedAt) * 100).rounded() / 100
        }

        func copyValue() -> DefaultCensusAgreement {
            return DefaultCensusAgreement(
                code: code,
                title: title,
                externalRef: externalRef,
                limit: limit,
                channel: channel,
                contactEmail: contactEmail,
                batchSize: batchSize,
                updatedAt: updatedAt,
                refills: refills,
                name: name,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a default census agreement in status created.
    static func newDefaultCensusAgreement(_ code: String, title: String) -> DefaultCensusAgreement {
        return DefaultCensusAgreement(
            code: code,
            title: title,
            externalRef: "",
            limit: 0,
            channel: "",
            contactEmail: "",
            batchSize: 0,
            updatedAt: 0,
            refills: 0,
            name: "",
            status: DefaultCensusAgreementStatus.created
        )
    }
}
