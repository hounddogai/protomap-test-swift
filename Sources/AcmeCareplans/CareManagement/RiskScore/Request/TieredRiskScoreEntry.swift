import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a tiered risk score entry is in its life cycle.
    enum TieredRiskScoreEntryStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A tiered risk score entry as the risk score team keeps it.
    final class TieredRiskScoreEntry {
        var code: String
        var name: String
        var rate: Double
        var country: String
        var threshold: Double
        var channel: String
        var revision: Int
        var clinicianID: String
        var status: TieredRiskScoreEntryStatus

        init(code: String, name: String, rate: Double, country: String, threshold: Double, channel: String, revision: Int, clinicianID: String, status: TieredRiskScoreEntryStatus) {
            self.code = code
            self.name = name
            self.rate = rate
            self.country = country
            self.threshold = threshold
            self.channel = channel
            self.revision = revision
            self.clinicianID = clinicianID
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

        func canMoveTo(_ next: TieredRiskScoreEntryStatus) -> Bool {
            switch status {
            case .created:
                return next == TieredRiskScoreEntryStatus.validated
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == TieredRiskScoreEntryStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredRiskScoreEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered risk score entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func weightedVolume() -> Double {
            return ((Double(revision) - rate) * 100).rounded() / 100
        }

        func copyValue() -> TieredRiskScoreEntry {
            return TieredRiskScoreEntry(
                code: code,
                name: name,
                rate: rate,
                country: country,
                threshold: threshold,
                channel: channel,
                revision: revision,
                clinicianID: clinicianID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a tiered risk score entry in status created.
    static func newTieredRiskScoreEntry(_ code: String, name: String) -> TieredRiskScoreEntry {
        return TieredRiskScoreEntry(
            code: code,
            name: name,
            rate: 0.0,
            country: "",
            threshold: 0.0,
            channel: "",
            revision: 0,
            clinicianID: "",
            status: TieredRiskScoreEntryStatus.created
        )
    }
}
