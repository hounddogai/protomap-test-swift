import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a care protocol override is in its life cycle.
    enum CareProtocolOverrideStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A care protocol override. Its code is unique within a tenant.
    final class CareProtocolOverride {
        var code: String
        var title: String
        var ratio: Double
        var visitMinutes: Int
        var procedureCode: String
        var score: Double
        var tags: [String]
        var rate: Double
        var ownerID: String
        var reviewer: String
        var capacity: Int
        var status: CareProtocolOverrideStatus

        init(code: String, title: String, ratio: Double, visitMinutes: Int, procedureCode: String, score: Double, tags: [String], rate: Double, ownerID: String, reviewer: String, capacity: Int, status: CareProtocolOverrideStatus) {
            self.code = code
            self.title = title
            self.ratio = ratio
            self.visitMinutes = visitMinutes
            self.procedureCode = procedureCode
            self.score = score
            self.tags = tags
            self.rate = rate
            self.ownerID = ownerID
            self.reviewer = reviewer
            self.capacity = capacity
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

        func canMoveTo(_ next: CareProtocolOverrideStatus) -> Bool {
            switch status {
            case .idle:
                return next == CareProtocolOverrideStatus.draining
            case .warming:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == CareProtocolOverrideStatus.draining
            case .draining:
                return next == CareProtocolOverrideStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareProtocolOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("care protocol override") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func netTotal() -> Double {
            return ((ratio - rate) * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolOverride {
            return CareProtocolOverride(
                code: code,
                title: title,
                ratio: ratio,
                visitMinutes: visitMinutes,
                procedureCode: procedureCode,
                score: score,
                tags: tags,
                rate: rate,
                ownerID: ownerID,
                reviewer: reviewer,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a care protocol override in status idle.
    static func newCareProtocolOverride(_ code: String, title: String) -> CareProtocolOverride {
        return CareProtocolOverride(
            code: code,
            title: title,
            ratio: 0.0,
            visitMinutes: 0,
            procedureCode: "",
            score: 0.0,
            tags: [],
            rate: 0.0,
            ownerID: "",
            reviewer: "",
            capacity: 0,
            status: CareProtocolOverrideStatus.idle
        )
    }
}
