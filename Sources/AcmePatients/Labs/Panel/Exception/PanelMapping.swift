import AcmePlatform
import Foundation

extension Labs {
    /// Where a panel mapping is in its life cycle.
    enum PanelMappingStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A panel mapping. Its code is unique within a tenant.
    final class PanelMapping {
        var code: String
        var name: String
        var ownerID: String
        var channel: String
        var phone: String
        var refills: Int
        var status: PanelMappingStatus

        init(code: String, name: String, ownerID: String, channel: String, phone: String, refills: Int, status: PanelMappingStatus) {
            self.code = code
            self.name = name
            self.ownerID = ownerID
            self.channel = channel
            self.phone = phone
            self.refills = refills
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PanelMappingStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == PanelMappingStatus.closed
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: PanelMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("panel mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func measuredValue() -> Double {
            return Double(refills)
        }

        func copyValue() -> PanelMapping {
            return PanelMapping(
                code: code,
                name: name,
                ownerID: ownerID,
                channel: channel,
                phone: phone,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a panel mapping in status draft.
    static func newPanelMapping(_ code: String, name: String) -> PanelMapping {
        return PanelMapping(
            code: code,
            name: name,
            ownerID: "",
            channel: "",
            phone: "",
            refills: 0,
            status: PanelMappingStatus.draft
        )
    }
}
