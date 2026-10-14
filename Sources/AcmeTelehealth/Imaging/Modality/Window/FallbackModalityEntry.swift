import AcmePlatform
import Foundation

extension Imaging {
    /// Where a fallback modality entry is in its life cycle.
    enum FallbackModalityEntryStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A fallback modality entry as the modality team keeps it.
    final class FallbackModalityEntry {
        var code: String
        var name: String
        var retries: Int
        var batchSize: Int
        var active: Bool
        var currency: String
        var status: FallbackModalityEntryStatus

        init(code: String, name: String, retries: Int, batchSize: Int, active: Bool, currency: String, status: FallbackModalityEntryStatus) {
            self.code = code
            self.name = name
            self.retries = retries
            self.batchSize = batchSize
            self.active = active
            self.currency = currency
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

        func canMoveTo(_ next: FallbackModalityEntryStatus) -> Bool {
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
                return next == FallbackModalityEntryStatus.ready || next == FallbackModalityEntryStatus.stopped
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

        func moveTo(_ next: FallbackModalityEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback modality entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func projectedExposure() -> Double {
            return ((Double(retries) - Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> FallbackModalityEntry {
            return FallbackModalityEntry(
                code: code,
                name: name,
                retries: retries,
                batchSize: batchSize,
                active: active,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a fallback modality entry in status idle.
    static func newFallbackModalityEntry(_ code: String, name: String) -> FallbackModalityEntry {
        return FallbackModalityEntry(
            code: code,
            name: name,
            retries: 0,
            batchSize: 0,
            active: false,
            currency: "",
            status: FallbackModalityEntryStatus.idle
        )
    }
}
