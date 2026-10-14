import AcmePlatform
import Foundation

extension Imaging {
    /// Where a adaptive care protocol budget is in its life cycle.
    enum AdaptiveCareProtocolBudgetStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a adaptive care protocol budget and its current status.
    final class AdaptiveCareProtocolBudget {
        var code: String
        var label: String
        var ratio: Double
        var minimum: Double
        var windowDays: Int
        var unit: String
        var checksum: String
        var allergy: String
        var tags: [String]
        var version: Int
        var status: AdaptiveCareProtocolBudgetStatus

        init(code: String, label: String, ratio: Double, minimum: Double, windowDays: Int, unit: String, checksum: String, allergy: String, tags: [String], version: Int, status: AdaptiveCareProtocolBudgetStatus) {
            self.code = code
            self.label = label
            self.ratio = ratio
            self.minimum = minimum
            self.windowDays = windowDays
            self.unit = unit
            self.checksum = checksum
            self.allergy = allergy
            self.tags = tags
            self.version = version
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

        func canMoveTo(_ next: AdaptiveCareProtocolBudgetStatus) -> Bool {
            switch status {
            case .proposed:
                return next == AdaptiveCareProtocolBudgetStatus.withdrawn
            case .approved:
                return next == AdaptiveCareProtocolBudgetStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: AdaptiveCareProtocolBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive care protocol budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedTotal() -> Double {
            return ((Double(windowDays) + minimum) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveCareProtocolBudget {
            return AdaptiveCareProtocolBudget(
                code: code,
                label: label,
                ratio: ratio,
                minimum: minimum,
                windowDays: windowDays,
                unit: unit,
                checksum: checksum,
                allergy: allergy,
                tags: tags,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a adaptive care protocol budget in status proposed.
    static func newAdaptiveCareProtocolBudget(_ code: String, label: String) -> AdaptiveCareProtocolBudget {
        return AdaptiveCareProtocolBudget(
            code: code,
            label: label,
            ratio: 0.0,
            minimum: 0.0,
            windowDays: 0,
            unit: "",
            checksum: "",
            allergy: "",
            tags: [],
            version: 0,
            status: AdaptiveCareProtocolBudgetStatus.proposed
        )
    }
}
