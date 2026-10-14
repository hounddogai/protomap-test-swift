import AcmePlatform
import Foundation

extension Consent {
    /// Where a fallback consent form notice is in its life cycle.
    enum FallbackConsentFormNoticeStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A fallback consent form notice. Its code is unique within a tenant.
    final class FallbackConsentFormNotice {
        var code: String
        var name: String
        var source: String
        var sequence: Int
        var bed: String
        var capacity: Int
        var ownerID: String
        var status: FallbackConsentFormNoticeStatus

        init(code: String, name: String, source: String, sequence: Int, bed: String, capacity: Int, ownerID: String, status: FallbackConsentFormNoticeStatus) {
            self.code = code
            self.name = name
            self.source = source
            self.sequence = sequence
            self.bed = bed
            self.capacity = capacity
            self.ownerID = ownerID
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FallbackConsentFormNoticeStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == FallbackConsentFormNoticeStatus.reopened || next == FallbackConsentFormNoticeStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: FallbackConsentFormNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback consent form notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func adjustedLoad() -> Double {
            return (Double(sequence) * Double(capacity) * 100).rounded() / 100
        }

        func copyValue() -> FallbackConsentFormNotice {
            return FallbackConsentFormNotice(
                code: code,
                name: name,
                source: source,
                sequence: sequence,
                bed: bed,
                capacity: capacity,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a fallback consent form notice in status open.
    static func newFallbackConsentFormNotice(_ code: String, name: String) -> FallbackConsentFormNotice {
        return FallbackConsentFormNotice(
            code: code,
            name: name,
            source: "",
            sequence: 0,
            bed: "",
            capacity: 0,
            ownerID: "",
            status: FallbackConsentFormNoticeStatus.`open`
        )
    }
}
