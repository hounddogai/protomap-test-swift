import AcmePlatform
import Foundation

extension Labs {
    /// Where a strict reference range request is in its life cycle.
    enum StrictReferenceRangeRequestStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a strict reference range request and its current status.
    final class StrictReferenceRangeRequest {
        var code: String
        var name: String
        var description: String
        var limit: Int
        var ceiling: Double
        var category: String
        var payer: String
        var status: StrictReferenceRangeRequestStatus

        init(code: String, name: String, description: String, limit: Int, ceiling: Double, category: String, payer: String, status: StrictReferenceRangeRequestStatus) {
            self.code = code
            self.name = name
            self.description = description
            self.limit = limit
            self.ceiling = ceiling
            self.category = category
            self.payer = payer
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

        func canMoveTo(_ next: StrictReferenceRangeRequestStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == StrictReferenceRangeRequestStatus.ready
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: StrictReferenceRangeRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict reference range request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("strict reference range request") \(code)"
        }

        func weightedVolume() -> Double {
            return ((Double(limit) - ceiling) * 100).rounded() / 100
        }

        func copyValue() -> StrictReferenceRangeRequest {
            return StrictReferenceRangeRequest(
                code: code,
                name: name,
                description: description,
                limit: limit,
                ceiling: ceiling,
                category: category,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a strict reference range request in status idle.
    static func newStrictReferenceRangeRequest(_ code: String, name: String) -> StrictReferenceRangeRequest {
        return StrictReferenceRangeRequest(
            code: code,
            name: name,
            description: "",
            limit: 0,
            ceiling: 0.0,
            category: "",
            payer: "",
            status: StrictReferenceRangeRequestStatus.idle
        )
    }
}
