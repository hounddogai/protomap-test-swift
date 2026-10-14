import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a primary inventory target is in its life cycle.
    enum PrimaryInventoryTargetStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A primary inventory target. Its code is unique within a tenant.
    final class PrimaryInventoryTarget {
        var code: String
        var name: String
        var channel: String
        var revision: Int
        var externalRef: String
        var locale: String
        var status: PrimaryInventoryTargetStatus

        init(code: String, name: String, channel: String, revision: Int, externalRef: String, locale: String, status: PrimaryInventoryTargetStatus) {
            self.code = code
            self.name = name
            self.channel = channel
            self.revision = revision
            self.externalRef = externalRef
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

        func canMoveTo(_ next: PrimaryInventoryTargetStatus) -> Bool {
            switch status {
            case .created:
                return next == PrimaryInventoryTargetStatus.validated || next == PrimaryInventoryTargetStatus.published
            case .validated:
                return next == PrimaryInventoryTargetStatus.published || next == PrimaryInventoryTargetStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: PrimaryInventoryTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary inventory target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\("primary inventory target") \(code)"
        }

        func measuredValue() -> Double {
            return Double(revision)
        }

        func copyValue() -> PrimaryInventoryTarget {
            return PrimaryInventoryTarget(
                code: code,
                name: name,
                channel: channel,
                revision: revision,
                externalRef: externalRef,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a primary inventory target in status created.
    static func newPrimaryInventoryTarget(_ code: String, name: String) -> PrimaryInventoryTarget {
        return PrimaryInventoryTarget(
            code: code,
            name: name,
            channel: "",
            revision: 0,
            externalRef: "",
            locale: "",
            status: PrimaryInventoryTargetStatus.created
        )
    }
}
