import AcmePlatform
import Foundation

extension Imaging {
    /// Where a care protocol score is in its life cycle.
    enum CareProtocolScoreStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a care protocol score and its current status.
    final class CareProtocolScore {
        var code: String
        var title: String
        var expiresAt: Int
        var country: String
        var source: String
        var updatedAt: Int
        var region: String
        var createdAt: Int
        var budget: Double
        var archived: Bool
        var status: CareProtocolScoreStatus

        init(code: String, title: String, expiresAt: Int, country: String, source: String, updatedAt: Int, region: String, createdAt: Int, budget: Double, archived: Bool, status: CareProtocolScoreStatus) {
            self.code = code
            self.title = title
            self.expiresAt = expiresAt
            self.country = country
            self.source = source
            self.updatedAt = updatedAt
            self.region = region
            self.createdAt = createdAt
            self.budget = budget
            self.archived = archived
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CareProtocolScoreStatus) -> Bool {
            switch status {
            case .idle:
                return next == CareProtocolScoreStatus.draining
            case .warming:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == CareProtocolScoreStatus.draining || next == CareProtocolScoreStatus.stopped
            case .draining:
                return next == CareProtocolScoreStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareProtocolScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func weightedExposure() -> Double {
            return ((Double(updatedAt) - Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolScore {
            return CareProtocolScore(
                code: code,
                title: title,
                expiresAt: expiresAt,
                country: country,
                source: source,
                updatedAt: updatedAt,
                region: region,
                createdAt: createdAt,
                budget: budget,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a care protocol score in status idle.
    static func newCareProtocolScore(_ code: String, title: String) -> CareProtocolScore {
        return CareProtocolScore(
            code: code,
            title: title,
            expiresAt: 0,
            country: "",
            source: "",
            updatedAt: 0,
            region: "",
            createdAt: 0,
            budget: 0.0,
            archived: false,
            status: CareProtocolScoreStatus.idle
        )
    }
}
