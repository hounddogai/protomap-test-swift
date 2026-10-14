import AcmePlatform
import Foundation

extension Referrals {
    /// Where a batched slot template is in its life cycle.
    enum BatchedSlotTemplateStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One batched slot template, with what the planners need to act on it.
    final class BatchedSlotTemplate {
        var code: String
        var name: String
        var ratio: Double
        var acuity: Int
        var score: Double
        var capacity: Int
        var source: String
        var procedureCode: String
        var visitMinutes: Int
        var approved: Bool
        var status: BatchedSlotTemplateStatus

        init(code: String, name: String, ratio: Double, acuity: Int, score: Double, capacity: Int, source: String, procedureCode: String, visitMinutes: Int, approved: Bool, status: BatchedSlotTemplateStatus) {
            self.code = code
            self.name = name
            self.ratio = ratio
            self.acuity = acuity
            self.score = score
            self.capacity = capacity
            self.source = source
            self.procedureCode = procedureCode
            self.visitMinutes = visitMinutes
            self.approved = approved
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

        func canMoveTo(_ next: BatchedSlotTemplateStatus) -> Bool {
            switch status {
            case .requested:
                return next == BatchedSlotTemplateStatus.revoked
            case .granted:
                return next == BatchedSlotTemplateStatus.revoked
            case .revoked:
                return next == BatchedSlotTemplateStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedSlotTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched slot template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("batched slot template") \(code)"
        }

        func netExposure() -> Double {
            return ((score + Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> BatchedSlotTemplate {
            return BatchedSlotTemplate(
                code: code,
                name: name,
                ratio: ratio,
                acuity: acuity,
                score: score,
                capacity: capacity,
                source: source,
                procedureCode: procedureCode,
                visitMinutes: visitMinutes,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a batched slot template in status requested.
    static func newBatchedSlotTemplate(_ code: String, name: String) -> BatchedSlotTemplate {
        return BatchedSlotTemplate(
            code: code,
            name: name,
            ratio: 0.0,
            acuity: 0,
            score: 0.0,
            capacity: 0,
            source: "",
            procedureCode: "",
            visitMinutes: 0,
            approved: false,
            status: BatchedSlotTemplateStatus.requested
        )
    }
}
