import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a remittance score is in its life cycle.
    enum RemittanceScoreStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A remittance score. Its code is unique within a tenant.
    final class RemittanceScore {
        var code: String
        var name: String
        var endsAt: Int
        var rate: Double
        var externalRef: String
        var startsAt: Int
        var bed: String
        var archived: Bool
        var revision: Int
        var status: RemittanceScoreStatus

        init(code: String, name: String, endsAt: Int, rate: Double, externalRef: String, startsAt: Int, bed: String, archived: Bool, revision: Int, status: RemittanceScoreStatus) {
            self.code = code
            self.name = name
            self.endsAt = endsAt
            self.rate = rate
            self.externalRef = externalRef
            self.startsAt = startsAt
            self.bed = bed
            self.archived = archived
            self.revision = revision
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

        func canMoveTo(_ next: RemittanceScoreStatus) -> Bool {
            switch status {
            case .created:
                return next == RemittanceScoreStatus.validated
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == RemittanceScoreStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RemittanceScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("remittance score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\("remittance score") \(code)"
        }

        func netVolume() -> Double {
            return (rate * Double(startsAt) * 100).rounded() / 100
        }

        func copyValue() -> RemittanceScore {
            return RemittanceScore(
                code: code,
                name: name,
                endsAt: endsAt,
                rate: rate,
                externalRef: externalRef,
                startsAt: startsAt,
                bed: bed,
                archived: archived,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a remittance score in status created.
    static func newRemittanceScore(_ code: String, name: String) -> RemittanceScore {
        return RemittanceScore(
            code: code,
            name: name,
            endsAt: 0,
            rate: 0.0,
            externalRef: "",
            startsAt: 0,
            bed: "",
            archived: false,
            revision: 0,
            status: RemittanceScoreStatus.created
        )
    }
}
