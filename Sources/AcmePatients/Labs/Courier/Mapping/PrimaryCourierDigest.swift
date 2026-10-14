import AcmePlatform
import Foundation

extension Labs {
    /// Where a primary courier digest is in its life cycle.
    enum PrimaryCourierDigestStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One primary courier digest, with what the planners need to act on it.
    final class PrimaryCourierDigest {
        var code: String
        var title: String
        var revision: Int
        var encounterID: String
        var dosageMg: Double
        var source: String
        var limit: Int
        var status: PrimaryCourierDigestStatus

        init(code: String, title: String, revision: Int, encounterID: String, dosageMg: Double, source: String, limit: Int, status: PrimaryCourierDigestStatus) {
            self.code = code
            self.title = title
            self.revision = revision
            self.encounterID = encounterID
            self.dosageMg = dosageMg
            self.source = source
            self.limit = limit
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

        func canMoveTo(_ next: PrimaryCourierDigestStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .running:
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
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == PrimaryCourierDigestStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryCourierDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary courier digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func effectiveLoad() -> Double {
            return (dosageMg * Double(limit) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryCourierDigest {
            return PrimaryCourierDigest(
                code: code,
                title: title,
                revision: revision,
                encounterID: encounterID,
                dosageMg: dosageMg,
                source: source,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a primary courier digest in status new.
    static func newPrimaryCourierDigest(_ code: String, title: String) -> PrimaryCourierDigest {
        return PrimaryCourierDigest(
            code: code,
            title: title,
            revision: 0,
            encounterID: "",
            dosageMg: 0.0,
            source: "",
            limit: 0,
            status: PrimaryCourierDigestStatus.new
        )
    }
}
