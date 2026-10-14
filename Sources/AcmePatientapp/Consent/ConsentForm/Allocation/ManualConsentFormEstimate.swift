import AcmePlatform
import Foundation

extension Consent {
    /// Where a manual consent form estimate is in its life cycle.
    enum ManualConsentFormEstimateStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a manual consent form estimate and its current status.
    final class ManualConsentFormEstimate {
        var code: String
        var name: String
        var amount: Double
        var expiresAt: Int
        var summary: String
        var ownerID: String
        var title: String
        var sequence: Int
        var version: Int
        var status: ManualConsentFormEstimateStatus

        init(code: String, name: String, amount: Double, expiresAt: Int, summary: String, ownerID: String, title: String, sequence: Int, version: Int, status: ManualConsentFormEstimateStatus) {
            self.code = code
            self.name = name
            self.amount = amount
            self.expiresAt = expiresAt
            self.summary = summary
            self.ownerID = ownerID
            self.title = title
            self.sequence = sequence
            self.version = version
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

        func canMoveTo(_ next: ManualConsentFormEstimateStatus) -> Bool {
            switch status {
            case .requested:
                return next == ManualConsentFormEstimateStatus.revoked || next == ManualConsentFormEstimateStatus.expired
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: ManualConsentFormEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual consent form estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func weightedValue() -> Double {
            return (Double(version) * Double(sequence) * 100).rounded() / 100
        }

        func copyValue() -> ManualConsentFormEstimate {
            return ManualConsentFormEstimate(
                code: code,
                name: name,
                amount: amount,
                expiresAt: expiresAt,
                summary: summary,
                ownerID: ownerID,
                title: title,
                sequence: sequence,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a manual consent form estimate in status requested.
    static func newManualConsentFormEstimate(_ code: String, name: String) -> ManualConsentFormEstimate {
        return ManualConsentFormEstimate(
            code: code,
            name: name,
            amount: 0.0,
            expiresAt: 0,
            summary: "",
            ownerID: "",
            title: "",
            sequence: 0,
            version: 0,
            status: ManualConsentFormEstimateStatus.requested
        )
    }
}
