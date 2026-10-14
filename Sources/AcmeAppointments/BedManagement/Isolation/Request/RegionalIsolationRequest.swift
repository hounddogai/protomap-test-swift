import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a regional isolation request is in its life cycle.
    enum RegionalIsolationRequestStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A regional isolation request as the isolation team keeps it.
    final class RegionalIsolationRequest {
        var code: String
        var title: String
        var rate: Double
        var tags: [String]
        var cost: Double
        var windowDays: Int
        var copay: Double
        var label: String
        var unit: String
        var status: RegionalIsolationRequestStatus

        init(code: String, title: String, rate: Double, tags: [String], cost: Double, windowDays: Int, copay: Double, label: String, unit: String, status: RegionalIsolationRequestStatus) {
            self.code = code
            self.title = title
            self.rate = rate
            self.tags = tags
            self.cost = cost
            self.windowDays = windowDays
            self.copay = copay
            self.label = label
            self.unit = unit
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

        func canMoveTo(_ next: RegionalIsolationRequestStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == RegionalIsolationRequestStatus.published
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

        func moveTo(_ next: RegionalIsolationRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional isolation request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(title)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedLoad() -> Double {
            return ((copay - cost) * 100).rounded() / 100
        }

        func copyValue() -> RegionalIsolationRequest {
            return RegionalIsolationRequest(
                code: code,
                title: title,
                rate: rate,
                tags: tags,
                cost: cost,
                windowDays: windowDays,
                copay: copay,
                label: label,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a regional isolation request in status created.
    static func newRegionalIsolationRequest(_ code: String, title: String) -> RegionalIsolationRequest {
        return RegionalIsolationRequest(
            code: code,
            title: title,
            rate: 0.0,
            tags: [],
            cost: 0.0,
            windowDays: 0,
            copay: 0.0,
            label: "",
            unit: "",
            status: RegionalIsolationRequestStatus.created
        )
    }
}
