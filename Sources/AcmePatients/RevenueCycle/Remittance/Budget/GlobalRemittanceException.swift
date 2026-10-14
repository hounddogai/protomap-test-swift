import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a global remittance exception is in its life cycle.
    enum GlobalRemittanceExceptionStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A global remittance exception as the remittance team keeps it.
    final class GlobalRemittanceException {
        var code: String
        var name: String
        var capacity: Int
        var active: Bool
        var facility: String
        var revision: Int
        var externalRef: String
        var createdAt: Int
        var status: GlobalRemittanceExceptionStatus

        init(code: String, name: String, capacity: Int, active: Bool, facility: String, revision: Int, externalRef: String, createdAt: Int, status: GlobalRemittanceExceptionStatus) {
            self.code = code
            self.name = name
            self.capacity = capacity
            self.active = active
            self.facility = facility
            self.revision = revision
            self.externalRef = externalRef
            self.createdAt = createdAt
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

        func canMoveTo(_ next: GlobalRemittanceExceptionStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == GlobalRemittanceExceptionStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalRemittanceExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global remittance exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func effectiveTotal() -> Double {
            return ((Double(capacity) - Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> GlobalRemittanceException {
            return GlobalRemittanceException(
                code: code,
                name: name,
                capacity: capacity,
                active: active,
                facility: facility,
                revision: revision,
                externalRef: externalRef,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a global remittance exception in status idle.
    static func newGlobalRemittanceException(_ code: String, name: String) -> GlobalRemittanceException {
        return GlobalRemittanceException(
            code: code,
            name: name,
            capacity: 0,
            active: false,
            facility: "",
            revision: 0,
            externalRef: "",
            createdAt: 0,
            status: GlobalRemittanceExceptionStatus.idle
        )
    }
}
