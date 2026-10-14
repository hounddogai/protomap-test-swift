import AcmePlatform
import Foundation

extension Imaging {
    /// Where a priority digest is in its life cycle.
    enum PriorityDigestStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One priority digest, with what the planners need to act on it.
    final class PriorityDigest {
        var code: String
        var title: String
        var clinicianID: String
        var description: String
        var batchSize: Int
        var locale: String
        var summary: String
        var minimum: Double
        var status: PriorityDigestStatus

        init(code: String, title: String, clinicianID: String, description: String, batchSize: Int, locale: String, summary: String, minimum: Double, status: PriorityDigestStatus) {
            self.code = code
            self.title = title
            self.clinicianID = clinicianID
            self.description = description
            self.batchSize = batchSize
            self.locale = locale
            self.summary = summary
            self.minimum = minimum
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

        func canMoveTo(_ next: PriorityDigestStatus) -> Bool {
            switch status {
            case .requested:
                return next == PriorityDigestStatus.expired
            case .granted:
                return next == PriorityDigestStatus.revoked
            case .revoked:
                return next == PriorityDigestStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PriorityDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("priority digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func projectedTotal() -> Double {
            return ((minimum + Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> PriorityDigest {
            return PriorityDigest(
                code: code,
                title: title,
                clinicianID: clinicianID,
                description: description,
                batchSize: batchSize,
                locale: locale,
                summary: summary,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a priority digest in status requested.
    static func newPriorityDigest(_ code: String, title: String) -> PriorityDigest {
        return PriorityDigest(
            code: code,
            title: title,
            clinicianID: "",
            description: "",
            batchSize: 0,
            locale: "",
            summary: "",
            minimum: 0.0,
            status: PriorityDigestStatus.requested
        )
    }
}
