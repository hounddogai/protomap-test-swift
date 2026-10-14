import AcmePlatform
import Foundation

extension Labs {
    /// Where a adaptive panel allocation is in its life cycle.
    enum AdaptivePanelAllocationStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A adaptive panel allocation. Its code is unique within a tenant.
    final class AdaptivePanelAllocation {
        var code: String
        var title: String
        var encounterID: String
        var copay: Double
        var summary: String
        var facility: String
        var name: String
        var attributes: [String: String]
        var windowDays: Int
        var capacity: Int
        var status: AdaptivePanelAllocationStatus

        init(code: String, title: String, encounterID: String, copay: Double, summary: String, facility: String, name: String, attributes: [String: String], windowDays: Int, capacity: Int, status: AdaptivePanelAllocationStatus) {
            self.code = code
            self.title = title
            self.encounterID = encounterID
            self.copay = copay
            self.summary = summary
            self.facility = facility
            self.name = name
            self.attributes = attributes
            self.windowDays = windowDays
            self.capacity = capacity
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

        func canMoveTo(_ next: AdaptivePanelAllocationStatus) -> Bool {
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
                return next == AdaptivePanelAllocationStatus.rejected || next == AdaptivePanelAllocationStatus.withdrawn
            case .rejected:
                return next == AdaptivePanelAllocationStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptivePanelAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive panel allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("adaptive panel allocation") \(code)"
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

        func weightedValue() -> Double {
            return ((Double(capacity) + copay) * 100).rounded() / 100
        }

        func copyValue() -> AdaptivePanelAllocation {
            return AdaptivePanelAllocation(
                code: code,
                title: title,
                encounterID: encounterID,
                copay: copay,
                summary: summary,
                facility: facility,
                name: name,
                attributes: attributes,
                windowDays: windowDays,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a adaptive panel allocation in status proposed.
    static func newAdaptivePanelAllocation(_ code: String, title: String) -> AdaptivePanelAllocation {
        return AdaptivePanelAllocation(
            code: code,
            title: title,
            encounterID: "",
            copay: 0.0,
            summary: "",
            facility: "",
            name: "",
            attributes: [:],
            windowDays: 0,
            capacity: 0,
            status: AdaptivePanelAllocationStatus.proposed
        )
    }
}
