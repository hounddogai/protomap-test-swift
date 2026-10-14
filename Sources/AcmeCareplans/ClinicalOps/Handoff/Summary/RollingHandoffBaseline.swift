import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a rolling handoff baseline is in its life cycle.
    enum RollingHandoffBaselineStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A rolling handoff baseline as the handoff team keeps it.
    final class RollingHandoffBaseline {
        var code: String
        var name: String
        var externalRef: String
        var checksum: String
        var attributes: [String: String]
        var capacity: Int
        var weight: Double
        var windowDays: Int
        var retries: Int
        var graceDays: Int
        var status: RollingHandoffBaselineStatus

        init(code: String, name: String, externalRef: String, checksum: String, attributes: [String: String], capacity: Int, weight: Double, windowDays: Int, retries: Int, graceDays: Int, status: RollingHandoffBaselineStatus) {
            self.code = code
            self.name = name
            self.externalRef = externalRef
            self.checksum = checksum
            self.attributes = attributes
            self.capacity = capacity
            self.weight = weight
            self.windowDays = windowDays
            self.retries = retries
            self.graceDays = graceDays
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RollingHandoffBaselineStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == RollingHandoffBaselineStatus.rejected
            case .rejected:
                return next == RollingHandoffBaselineStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingHandoffBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling handoff baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func effectiveTotal() -> Double {
            return (Double(capacity) * Double(windowDays) * 100).rounded() / 100
        }

        func copyValue() -> RollingHandoffBaseline {
            return RollingHandoffBaseline(
                code: code,
                name: name,
                externalRef: externalRef,
                checksum: checksum,
                attributes: attributes,
                capacity: capacity,
                weight: weight,
                windowDays: windowDays,
                retries: retries,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a rolling handoff baseline in status proposed.
    static func newRollingHandoffBaseline(_ code: String, name: String) -> RollingHandoffBaseline {
        return RollingHandoffBaseline(
            code: code,
            name: name,
            externalRef: "",
            checksum: "",
            attributes: [:],
            capacity: 0,
            weight: 0.0,
            windowDays: 0,
            retries: 0,
            graceDays: 0,
            status: RollingHandoffBaselineStatus.proposed
        )
    }
}
