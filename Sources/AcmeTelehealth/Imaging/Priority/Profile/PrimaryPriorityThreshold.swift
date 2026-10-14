import AcmePlatform
import Foundation

extension Imaging {
    /// Where a primary priority threshold is in its life cycle.
    enum PrimaryPriorityThresholdStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A primary priority threshold. Its code is unique within a tenant.
    final class PrimaryPriorityThreshold {
        var code: String
        var name: String
        var clinicianID: String
        var retries: Int
        var title: String
        var rate: Double
        var attempts: Int
        var source: String
        var locale: String
        var status: PrimaryPriorityThresholdStatus

        init(code: String, name: String, clinicianID: String, retries: Int, title: String, rate: Double, attempts: Int, source: String, locale: String, status: PrimaryPriorityThresholdStatus) {
            self.code = code
            self.name = name
            self.clinicianID = clinicianID
            self.retries = retries
            self.title = title
            self.rate = rate
            self.attempts = attempts
            self.source = source
            self.locale = locale
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

        func canMoveTo(_ next: PrimaryPriorityThresholdStatus) -> Bool {
            switch status {
            case .created:
                return next == PrimaryPriorityThresholdStatus.validated
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == PrimaryPriorityThresholdStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryPriorityThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary priority threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("primary priority threshold") \(code)"
        }

        func netValue() -> Double {
            return ((rate + Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryPriorityThreshold {
            return PrimaryPriorityThreshold(
                code: code,
                name: name,
                clinicianID: clinicianID,
                retries: retries,
                title: title,
                rate: rate,
                attempts: attempts,
                source: source,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a primary priority threshold in status created.
    static func newPrimaryPriorityThreshold(_ code: String, name: String) -> PrimaryPriorityThreshold {
        return PrimaryPriorityThreshold(
            code: code,
            name: name,
            clinicianID: "",
            retries: 0,
            title: "",
            rate: 0.0,
            attempts: 0,
            source: "",
            locale: "",
            status: PrimaryPriorityThresholdStatus.created
        )
    }
}
