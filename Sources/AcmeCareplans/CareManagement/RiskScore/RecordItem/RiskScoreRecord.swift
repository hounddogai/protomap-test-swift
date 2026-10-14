import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a risk score record is in its life cycle.
    enum RiskScoreRecordStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A risk score record as the risk score team keeps it.
    final class RiskScoreRecord {
        var code: String
        var name: String
        var channel: String
        var dosageMg: Double
        var attributes: [String: String]
        var encounterID: String
        var score: Double
        var region: String
        var status: RiskScoreRecordStatus

        init(code: String, name: String, channel: String, dosageMg: Double, attributes: [String: String], encounterID: String, score: Double, region: String, status: RiskScoreRecordStatus) {
            self.code = code
            self.name = name
            self.channel = channel
            self.dosageMg = dosageMg
            self.attributes = attributes
            self.encounterID = encounterID
            self.score = score
            self.region = region
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

        func canMoveTo(_ next: RiskScoreRecordStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == RiskScoreRecordStatus.revoked
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: RiskScoreRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("risk score record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
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

        func projectedValue() -> Double {
            return ((score + dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> RiskScoreRecord {
            return RiskScoreRecord(
                code: code,
                name: name,
                channel: channel,
                dosageMg: dosageMg,
                attributes: attributes,
                encounterID: encounterID,
                score: score,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a risk score record in status requested.
    static func newRiskScoreRecord(_ code: String, name: String) -> RiskScoreRecord {
        return RiskScoreRecord(
            code: code,
            name: name,
            channel: "",
            dosageMg: 0.0,
            attributes: [:],
            encounterID: "",
            score: 0.0,
            region: "",
            status: RiskScoreRecordStatus.requested
        )
    }
}
