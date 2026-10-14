import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a primary inventory agreement is in its life cycle.
    enum PrimaryInventoryAgreementStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a primary inventory agreement and its current status.
    final class PrimaryInventoryAgreement {
        var code: String
        var title: String
        var country: String
        var graceDays: Int
        var minimum: Double
        var threshold: Double
        var bed: String
        var weight: Double
        var version: Int
        var priority: Int
        var status: PrimaryInventoryAgreementStatus

        init(code: String, title: String, country: String, graceDays: Int, minimum: Double, threshold: Double, bed: String, weight: Double, version: Int, priority: Int, status: PrimaryInventoryAgreementStatus) {
            self.code = code
            self.title = title
            self.country = country
            self.graceDays = graceDays
            self.minimum = minimum
            self.threshold = threshold
            self.bed = bed
            self.weight = weight
            self.version = version
            self.priority = priority
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

        func canMoveTo(_ next: PrimaryInventoryAgreementStatus) -> Bool {
            switch status {
            case .idle:
                return next == PrimaryInventoryAgreementStatus.ready
            case .warming:
                return next == PrimaryInventoryAgreementStatus.ready
            case .ready:
                return next == PrimaryInventoryAgreementStatus.draining || next == PrimaryInventoryAgreementStatus.stopped
            case .draining:
                return next == PrimaryInventoryAgreementStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryInventoryAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary inventory agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func effectiveLoad() -> Double {
            return ((Double(graceDays) + Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryInventoryAgreement {
            return PrimaryInventoryAgreement(
                code: code,
                title: title,
                country: country,
                graceDays: graceDays,
                minimum: minimum,
                threshold: threshold,
                bed: bed,
                weight: weight,
                version: version,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a primary inventory agreement in status idle.
    static func newPrimaryInventoryAgreement(_ code: String, title: String) -> PrimaryInventoryAgreement {
        return PrimaryInventoryAgreement(
            code: code,
            title: title,
            country: "",
            graceDays: 0,
            minimum: 0.0,
            threshold: 0.0,
            bed: "",
            weight: 0.0,
            version: 0,
            priority: 0,
            status: PrimaryInventoryAgreementStatus.idle
        )
    }
}
