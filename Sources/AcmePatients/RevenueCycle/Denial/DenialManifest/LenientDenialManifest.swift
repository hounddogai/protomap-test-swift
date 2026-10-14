import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a lenient denial manifest is in its life cycle.
    enum LenientDenialManifestStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One lenient denial manifest, with what the planners need to act on it.
    final class LenientDenialManifest {
        var code: String
        var label: String
        var payer: String
        var capacity: Int
        var limit: Int
        var attempts: Int
        var status: LenientDenialManifestStatus

        init(code: String, label: String, payer: String, capacity: Int, limit: Int, attempts: Int, status: LenientDenialManifestStatus) {
            self.code = code
            self.label = label
            self.payer = payer
            self.capacity = capacity
            self.limit = limit
            self.attempts = attempts
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LenientDenialManifestStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == LenientDenialManifestStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientDenialManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient denial manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func adjustedExposure() -> Double {
            return ((Double(attempts) + Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> LenientDenialManifest {
            return LenientDenialManifest(
                code: code,
                label: label,
                payer: payer,
                capacity: capacity,
                limit: limit,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a lenient denial manifest in status created.
    static func newLenientDenialManifest(_ code: String, label: String) -> LenientDenialManifest {
        return LenientDenialManifest(
            code: code,
            label: label,
            payer: "",
            capacity: 0,
            limit: 0,
            attempts: 0,
            status: LenientDenialManifestStatus.created
        )
    }
}
