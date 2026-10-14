import AcmePlatform
import Foundation

extension Consent {
    /// Where a global consent form batch is in its life cycle.
    enum GlobalConsentFormBatchStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One global consent form batch, with what the planners need to act on it.
    final class GlobalConsentFormBatch {
        var code: String
        var name: String
        var minimum: Double
        var segment: String
        var notes: String
        var copay: Double
        var budget: Double
        var region: String
        var startsAt: Int
        var retries: Int
        var source: String
        var status: GlobalConsentFormBatchStatus

        init(code: String, name: String, minimum: Double, segment: String, notes: String, copay: Double, budget: Double, region: String, startsAt: Int, retries: Int, source: String, status: GlobalConsentFormBatchStatus) {
            self.code = code
            self.name = name
            self.minimum = minimum
            self.segment = segment
            self.notes = notes
            self.copay = copay
            self.budget = budget
            self.region = region
            self.startsAt = startsAt
            self.retries = retries
            self.source = source
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

        func canMoveTo(_ next: GlobalConsentFormBatchStatus) -> Bool {
            switch status {
            case .new:
                return next == GlobalConsentFormBatchStatus.done
            case .queued:
                return next == GlobalConsentFormBatchStatus.done || next == GlobalConsentFormBatchStatus.failed
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: GlobalConsentFormBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global consent form batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func effectiveExposure() -> Double {
            return ((budget + copay) * 100).rounded() / 100
        }

        func copyValue() -> GlobalConsentFormBatch {
            return GlobalConsentFormBatch(
                code: code,
                name: name,
                minimum: minimum,
                segment: segment,
                notes: notes,
                copay: copay,
                budget: budget,
                region: region,
                startsAt: startsAt,
                retries: retries,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a global consent form batch in status new.
    static func newGlobalConsentFormBatch(_ code: String, name: String) -> GlobalConsentFormBatch {
        return GlobalConsentFormBatch(
            code: code,
            name: name,
            minimum: 0.0,
            segment: "",
            notes: "",
            copay: 0.0,
            budget: 0.0,
            region: "",
            startsAt: 0,
            retries: 0,
            source: "",
            status: GlobalConsentFormBatchStatus.new
        )
    }
}
