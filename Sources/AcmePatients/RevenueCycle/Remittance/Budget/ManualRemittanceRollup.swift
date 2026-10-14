import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a manual remittance rollup is in its life cycle.
    enum ManualRemittanceRollupStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a manual remittance rollup and its current status.
    final class ManualRemittanceRollup {
        var code: String
        var name: String
        var region: String
        var approved: Bool
        var description: String
        var ownerID: String
        var durationMinutes: Int
        var status: ManualRemittanceRollupStatus

        init(code: String, name: String, region: String, approved: Bool, description: String, ownerID: String, durationMinutes: Int, status: ManualRemittanceRollupStatus) {
            self.code = code
            self.name = name
            self.region = region
            self.approved = approved
            self.description = description
            self.ownerID = ownerID
            self.durationMinutes = durationMinutes
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

        func canMoveTo(_ next: ManualRemittanceRollupStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == ManualRemittanceRollupStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualRemittanceRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual remittance rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func measuredValue() -> Double {
            return Double(durationMinutes)
        }

        func copyValue() -> ManualRemittanceRollup {
            return ManualRemittanceRollup(
                code: code,
                name: name,
                region: region,
                approved: approved,
                description: description,
                ownerID: ownerID,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a manual remittance rollup in status created.
    static func newManualRemittanceRollup(_ code: String, name: String) -> ManualRemittanceRollup {
        return ManualRemittanceRollup(
            code: code,
            name: name,
            region: "",
            approved: false,
            description: "",
            ownerID: "",
            durationMinutes: 0,
            status: ManualRemittanceRollupStatus.created
        )
    }
}
