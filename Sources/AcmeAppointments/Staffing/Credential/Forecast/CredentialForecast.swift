import AcmePlatform
import Foundation

extension Staffing {
    /// Where a credential forecast is in its life cycle.
    enum CredentialForecastStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A credential forecast as the credential team keeps it.
    final class CredentialForecast {
        var code: String
        var title: String
        var archived: Bool
        var margin: Double
        var payer: String
        var ownerID: String
        var weight: Double
        var source: String
        var batchSize: Int
        var limit: Int
        var checksum: String
        var status: CredentialForecastStatus

        init(code: String, title: String, archived: Bool, margin: Double, payer: String, ownerID: String, weight: Double, source: String, batchSize: Int, limit: Int, checksum: String, status: CredentialForecastStatus) {
            self.code = code
            self.title = title
            self.archived = archived
            self.margin = margin
            self.payer = payer
            self.ownerID = ownerID
            self.weight = weight
            self.source = source
            self.batchSize = batchSize
            self.limit = limit
            self.checksum = checksum
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CredentialForecastStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == CredentialForecastStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CredentialForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("credential forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func effectiveLoad() -> Double {
            return ((weight - margin) * 100).rounded() / 100
        }

        func copyValue() -> CredentialForecast {
            return CredentialForecast(
                code: code,
                title: title,
                archived: archived,
                margin: margin,
                payer: payer,
                ownerID: ownerID,
                weight: weight,
                source: source,
                batchSize: batchSize,
                limit: limit,
                checksum: checksum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a credential forecast in status new.
    static func newCredentialForecast(_ code: String, title: String) -> CredentialForecast {
        return CredentialForecast(
            code: code,
            title: title,
            archived: false,
            margin: 0.0,
            payer: "",
            ownerID: "",
            weight: 0.0,
            source: "",
            batchSize: 0,
            limit: 0,
            checksum: "",
            status: CredentialForecastStatus.new
        )
    }
}
