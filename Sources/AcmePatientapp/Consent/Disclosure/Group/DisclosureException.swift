import AcmePlatform
import Foundation

extension Consent {
    /// Where a disclosure exception is in its life cycle.
    enum DisclosureExceptionStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a disclosure exception and its current status.
    final class DisclosureException {
        var code: String
        var name: String
        var ceiling: Double
        var contactEmail: String
        var facility: String
        var batchSize: Int
        var status: DisclosureExceptionStatus

        init(code: String, name: String, ceiling: Double, contactEmail: String, facility: String, batchSize: Int, status: DisclosureExceptionStatus) {
            self.code = code
            self.name = name
            self.ceiling = ceiling
            self.contactEmail = contactEmail
            self.facility = facility
            self.batchSize = batchSize
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

        func canMoveTo(_ next: DisclosureExceptionStatus) -> Bool {
            switch status {
            case .new:
                return next == DisclosureExceptionStatus.queued || next == DisclosureExceptionStatus.running
            case .queued:
                return next == DisclosureExceptionStatus.running || next == DisclosureExceptionStatus.failed
            case .running:
                switch next {
                case .failed:
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

        func moveTo(_ next: DisclosureExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("disclosure exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func weightedValue() -> Double {
            return ((ceiling - Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> DisclosureException {
            return DisclosureException(
                code: code,
                name: name,
                ceiling: ceiling,
                contactEmail: contactEmail,
                facility: facility,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a disclosure exception in status new.
    static func newDisclosureException(_ code: String, name: String) -> DisclosureException {
        return DisclosureException(
            code: code,
            name: name,
            ceiling: 0.0,
            contactEmail: "",
            facility: "",
            batchSize: 0,
            status: DisclosureExceptionStatus.new
        )
    }
}
