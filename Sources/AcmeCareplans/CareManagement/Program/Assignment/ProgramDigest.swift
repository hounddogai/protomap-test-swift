import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a program digest is in its life cycle.
    enum ProgramDigestStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One program digest, with what the planners need to act on it.
    final class ProgramDigest {
        var code: String
        var name: String
        var maximum: Double
        var copay: Double
        var region: String
        var score: Double
        var updatedAt: Int
        var status: ProgramDigestStatus

        init(code: String, name: String, maximum: Double, copay: Double, region: String, score: Double, updatedAt: Int, status: ProgramDigestStatus) {
            self.code = code
            self.name = name
            self.maximum = maximum
            self.copay = copay
            self.region = region
            self.score = score
            self.updatedAt = updatedAt
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

        func canMoveTo(_ next: ProgramDigestStatus) -> Bool {
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
                return next == ProgramDigestStatus.stopped
            case .draining:
                return next == ProgramDigestStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ProgramDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("program digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func projectedVolume() -> Double {
            return (copay * score * 100).rounded() / 100
        }

        func copyValue() -> ProgramDigest {
            return ProgramDigest(
                code: code,
                name: name,
                maximum: maximum,
                copay: copay,
                region: region,
                score: score,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a program digest in status idle.
    static func newProgramDigest(_ code: String, name: String) -> ProgramDigest {
        return ProgramDigest(
            code: code,
            name: name,
            maximum: 0.0,
            copay: 0.0,
            region: "",
            score: 0.0,
            updatedAt: 0,
            status: ProgramDigestStatus.idle
        )
    }
}
