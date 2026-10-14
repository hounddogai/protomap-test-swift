import AcmePlatform
import Foundation

extension Consent {
    /// Where a language entry is in its life cycle.
    enum LanguageEntryStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One language entry, with what the planners need to act on it.
    final class LanguageEntry {
        var code: String
        var label: String
        var copay: Double
        var acuity: Int
        var limit: Int
        var retries: Int
        var ceiling: Double
        var status: LanguageEntryStatus

        init(code: String, label: String, copay: Double, acuity: Int, limit: Int, retries: Int, ceiling: Double, status: LanguageEntryStatus) {
            self.code = code
            self.label = label
            self.copay = copay
            self.acuity = acuity
            self.limit = limit
            self.retries = retries
            self.ceiling = ceiling
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

        func canMoveTo(_ next: LanguageEntryStatus) -> Bool {
            switch status {
            case .idle:
                return next == LanguageEntryStatus.ready || next == LanguageEntryStatus.draining
            case .warming:
                return next == LanguageEntryStatus.stopped
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

        func moveTo(_ next: LanguageEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("language entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("language entry") \(code)"
        }

        func weightedExposure() -> Double {
            return (ceiling * copay * 100).rounded() / 100
        }

        func copyValue() -> LanguageEntry {
            return LanguageEntry(
                code: code,
                label: label,
                copay: copay,
                acuity: acuity,
                limit: limit,
                retries: retries,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a language entry in status idle.
    static func newLanguageEntry(_ code: String, label: String) -> LanguageEntry {
        return LanguageEntry(
            code: code,
            label: label,
            copay: 0.0,
            acuity: 0,
            limit: 0,
            retries: 0,
            ceiling: 0.0,
            status: LanguageEntryStatus.idle
        )
    }
}
