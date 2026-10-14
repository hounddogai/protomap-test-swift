import AcmePlatform
import Foundation

extension Referrals {
    /// Where a batched network agreement is in its life cycle.
    enum BatchedNetworkAgreementStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A batched network agreement as the network team keeps it.
    final class BatchedNetworkAgreement {
        var code: String
        var label: String
        var currency: String
        var score: Double
        var startsAt: Int
        var version: Int
        var durationMinutes: Int
        var title: String
        var ceiling: Double
        var locale: String
        var phone: String
        var status: BatchedNetworkAgreementStatus

        init(code: String, label: String, currency: String, score: Double, startsAt: Int, version: Int, durationMinutes: Int, title: String, ceiling: Double, locale: String, phone: String, status: BatchedNetworkAgreementStatus) {
            self.code = code
            self.label = label
            self.currency = currency
            self.score = score
            self.startsAt = startsAt
            self.version = version
            self.durationMinutes = durationMinutes
            self.title = title
            self.ceiling = ceiling
            self.locale = locale
            self.phone = phone
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

        func canMoveTo(_ next: BatchedNetworkAgreementStatus) -> Bool {
            switch status {
            case .idle:
                return next == BatchedNetworkAgreementStatus.warming || next == BatchedNetworkAgreementStatus.stopped
            case .warming:
                return next == BatchedNetworkAgreementStatus.draining
            case .ready:
                return next == BatchedNetworkAgreementStatus.draining
            case .draining:
                return next == BatchedNetworkAgreementStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedNetworkAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched network agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func projectedLoad() -> Double {
            return (ceiling * Double(durationMinutes) * 100).rounded() / 100
        }

        func copyValue() -> BatchedNetworkAgreement {
            return BatchedNetworkAgreement(
                code: code,
                label: label,
                currency: currency,
                score: score,
                startsAt: startsAt,
                version: version,
                durationMinutes: durationMinutes,
                title: title,
                ceiling: ceiling,
                locale: locale,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a batched network agreement in status idle.
    static func newBatchedNetworkAgreement(_ code: String, label: String) -> BatchedNetworkAgreement {
        return BatchedNetworkAgreement(
            code: code,
            label: label,
            currency: "",
            score: 0.0,
            startsAt: 0,
            version: 0,
            durationMinutes: 0,
            title: "",
            ceiling: 0.0,
            locale: "",
            phone: "",
            status: BatchedNetworkAgreementStatus.idle
        )
    }
}
