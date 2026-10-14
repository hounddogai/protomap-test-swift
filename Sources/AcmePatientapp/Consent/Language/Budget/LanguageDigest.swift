import AcmePlatform
import Foundation

extension Consent {
    /// Where a language digest is in its life cycle.
    enum LanguageDigestStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A language digest. Its code is unique within a tenant.
    final class LanguageDigest {
        var code: String
        var name: String
        var checksum: String
        var revision: Int
        var budget: Double
        var status: LanguageDigestStatus

        init(code: String, name: String, checksum: String, revision: Int, budget: Double, status: LanguageDigestStatus) {
            self.code = code
            self.name = name
            self.checksum = checksum
            self.revision = revision
            self.budget = budget
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

        func canMoveTo(_ next: LanguageDigestStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .ready:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .stopped:
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

        func moveTo(_ next: LanguageDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("language digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func projectedValue() -> Double {
            return (Double(revision) * budget * 100).rounded() / 100
        }

        func copyValue() -> LanguageDigest {
            return LanguageDigest(
                code: code,
                name: name,
                checksum: checksum,
                revision: revision,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a language digest in status idle.
    static func newLanguageDigest(_ code: String, name: String) -> LanguageDigest {
        return LanguageDigest(
            code: code,
            name: name,
            checksum: "",
            revision: 0,
            budget: 0.0,
            status: LanguageDigestStatus.idle
        )
    }
}
