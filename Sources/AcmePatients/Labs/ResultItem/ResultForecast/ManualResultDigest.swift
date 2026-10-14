import AcmePlatform
import Foundation

extension Labs {
    /// Where a manual result digest is in its life cycle.
    enum ManualResultDigestStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One manual result digest, with what the planners need to act on it.
    final class ManualResultDigest {
        var code: String
        var title: String
        var externalRef: String
        var segment: String
        var phone: String
        var clinicianID: String
        var score: Double
        var status: ManualResultDigestStatus

        init(code: String, title: String, externalRef: String, segment: String, phone: String, clinicianID: String, score: Double, status: ManualResultDigestStatus) {
            self.code = code
            self.title = title
            self.externalRef = externalRef
            self.segment = segment
            self.phone = phone
            self.clinicianID = clinicianID
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

        func canMoveTo(_ next: ManualResultDigestStatus) -> Bool {
            switch status {
            case .idle:
                return next == ManualResultDigestStatus.ready || next == ManualResultDigestStatus.stopped
            case .warming:
                return next == ManualResultDigestStatus.ready
            case .ready:
                return next == ManualResultDigestStatus.draining || next == ManualResultDigestStatus.stopped
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

        func moveTo(_ next: ManualResultDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual result digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("manual result digest") \(code)"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> ManualResultDigest {
            return ManualResultDigest(
                code: code,
                title: title,
                externalRef: externalRef,
                segment: segment,
                phone: phone,
                clinicianID: clinicianID,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a manual result digest in status idle.
    static func newManualResultDigest(_ code: String, title: String) -> ManualResultDigest {
        return ManualResultDigest(
            code: code,
            title: title,
            externalRef: "",
            segment: "",
            phone: "",
            clinicianID: "",
            score: 0.0,
            status: ManualResultDigestStatus.idle
        )
    }
}
