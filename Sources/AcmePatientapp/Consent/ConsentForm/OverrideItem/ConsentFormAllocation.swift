import AcmePlatform
import Foundation

extension Consent {
    /// Where a consent form allocation is in its life cycle.
    enum ConsentFormAllocationStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One consent form allocation, with what the planners need to act on it.
    final class ConsentFormAllocation {
        var code: String
        var title: String
        var attempts: Int
        var floorValue: Double
        var sequence: Int
        var limit: Int
        var facility: String
        var budget: Double
        var locale: String
        var pinned: Bool
        var retries: Int
        var status: ConsentFormAllocationStatus

        init(code: String, title: String, attempts: Int, floorValue: Double, sequence: Int, limit: Int, facility: String, budget: Double, locale: String, pinned: Bool, retries: Int, status: ConsentFormAllocationStatus) {
            self.code = code
            self.title = title
            self.attempts = attempts
            self.floorValue = floorValue
            self.sequence = sequence
            self.limit = limit
            self.facility = facility
            self.budget = budget
            self.locale = locale
            self.pinned = pinned
            self.retries = retries
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ConsentFormAllocationStatus) -> Bool {
            switch status {
            case .requested:
                return next == ConsentFormAllocationStatus.granted || next == ConsentFormAllocationStatus.expired
            case .granted:
                return next == ConsentFormAllocationStatus.revoked
            case .revoked:
                return next == ConsentFormAllocationStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ConsentFormAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("consent form allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func effectiveLoad() -> Double {
            return ((Double(limit) - Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> ConsentFormAllocation {
            return ConsentFormAllocation(
                code: code,
                title: title,
                attempts: attempts,
                floorValue: floorValue,
                sequence: sequence,
                limit: limit,
                facility: facility,
                budget: budget,
                locale: locale,
                pinned: pinned,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a consent form allocation in status requested.
    static func newConsentFormAllocation(_ code: String, title: String) -> ConsentFormAllocation {
        return ConsentFormAllocation(
            code: code,
            title: title,
            attempts: 0,
            floorValue: 0.0,
            sequence: 0,
            limit: 0,
            facility: "",
            budget: 0.0,
            locale: "",
            pinned: false,
            retries: 0,
            status: ConsentFormAllocationStatus.requested
        )
    }
}
