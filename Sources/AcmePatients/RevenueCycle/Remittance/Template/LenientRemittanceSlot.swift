import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a lenient remittance slot is in its life cycle.
    enum LenientRemittanceSlotStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A lenient remittance slot. Its code is unique within a tenant.
    final class LenientRemittanceSlot {
        var code: String
        var title: String
        var region: String
        var segment: String
        var version: Int
        var status: LenientRemittanceSlotStatus

        init(code: String, title: String, region: String, segment: String, version: Int, status: LenientRemittanceSlotStatus) {
            self.code = code
            self.title = title
            self.region = region
            self.segment = segment
            self.version = version
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

        func canMoveTo(_ next: LenientRemittanceSlotStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: LenientRemittanceSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient remittance slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func measuredValue() -> Double {
            return Double(version)
        }

        func copyValue() -> LenientRemittanceSlot {
            return LenientRemittanceSlot(
                code: code,
                title: title,
                region: region,
                segment: segment,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a lenient remittance slot in status created.
    static func newLenientRemittanceSlot(_ code: String, title: String) -> LenientRemittanceSlot {
        return LenientRemittanceSlot(
            code: code,
            title: title,
            region: "",
            segment: "",
            version: 0,
            status: LenientRemittanceSlotStatus.created
        )
    }
}
