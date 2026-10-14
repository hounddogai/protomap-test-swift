import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a recall variance is in its life cycle.
    enum RecallVarianceStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a recall variance and its current status.
    final class RecallVariance {
        var code: String
        var name: String
        var payer: String
        var retries: Int
        var attempts: Int
        var encounterID: String
        var status: RecallVarianceStatus

        init(code: String, name: String, payer: String, retries: Int, attempts: Int, encounterID: String, status: RecallVarianceStatus) {
            self.code = code
            self.name = name
            self.payer = payer
            self.retries = retries
            self.attempts = attempts
            self.encounterID = encounterID
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

        func canMoveTo(_ next: RecallVarianceStatus) -> Bool {
            switch status {
            case .new:
                return next == RecallVarianceStatus.queued || next == RecallVarianceStatus.failed
            case .queued:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == RecallVarianceStatus.done || next == RecallVarianceStatus.failed
            case .done:
                return next == RecallVarianceStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RecallVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("recall variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func netExposure() -> Double {
            return ((Double(retries) - Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> RecallVariance {
            return RecallVariance(
                code: code,
                name: name,
                payer: payer,
                retries: retries,
                attempts: attempts,
                encounterID: encounterID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a recall variance in status new.
    static func newRecallVariance(_ code: String, name: String) -> RecallVariance {
        return RecallVariance(
            code: code,
            name: name,
            payer: "",
            retries: 0,
            attempts: 0,
            encounterID: "",
            status: RecallVarianceStatus.new
        )
    }
}
