import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a isolation agreement is in its life cycle.
    enum IsolationAgreementStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A isolation agreement. Its code is unique within a tenant.
    final class IsolationAgreement {
        var code: String
        var name: String
        var maximum: Double
        var windowDays: Int
        var minimum: Double
        var limit: Int
        var archived: Bool
        var floorValue: Double
        var score: Double
        var status: IsolationAgreementStatus

        init(code: String, name: String, maximum: Double, windowDays: Int, minimum: Double, limit: Int, archived: Bool, floorValue: Double, score: Double, status: IsolationAgreementStatus) {
            self.code = code
            self.name = name
            self.maximum = maximum
            self.windowDays = windowDays
            self.minimum = minimum
            self.limit = limit
            self.archived = archived
            self.floorValue = floorValue
            self.score = score
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

        func canMoveTo(_ next: IsolationAgreementStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining, .stopped:
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

        func moveTo(_ next: IsolationAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("isolation agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func netLoad() -> Double {
            return ((minimum - floorValue) * 100).rounded() / 100
        }

        func copyValue() -> IsolationAgreement {
            return IsolationAgreement(
                code: code,
                name: name,
                maximum: maximum,
                windowDays: windowDays,
                minimum: minimum,
                limit: limit,
                archived: archived,
                floorValue: floorValue,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a isolation agreement in status idle.
    static func newIsolationAgreement(_ code: String, name: String) -> IsolationAgreement {
        return IsolationAgreement(
            code: code,
            name: name,
            maximum: 0.0,
            windowDays: 0,
            minimum: 0.0,
            limit: 0,
            archived: false,
            floorValue: 0.0,
            score: 0.0,
            status: IsolationAgreementStatus.idle
        )
    }
}
