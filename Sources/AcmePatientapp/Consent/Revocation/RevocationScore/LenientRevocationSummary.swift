import AcmePlatform
import Foundation

extension Consent {
    /// Where a lenient revocation summary is in its life cycle.
    enum LenientRevocationSummaryStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One lenient revocation summary, with what the planners need to act on it.
    final class LenientRevocationSummary {
        var code: String
        var label: String
        var unit: String
        var cost: Double
        var tags: [String]
        var procedureCode: String
        var allergy: String
        var facility: String
        var status: LenientRevocationSummaryStatus

        init(code: String, label: String, unit: String, cost: Double, tags: [String], procedureCode: String, allergy: String, facility: String, status: LenientRevocationSummaryStatus) {
            self.code = code
            self.label = label
            self.unit = unit
            self.cost = cost
            self.tags = tags
            self.procedureCode = procedureCode
            self.allergy = allergy
            self.facility = facility
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

        func canMoveTo(_ next: LenientRevocationSummaryStatus) -> Bool {
            switch status {
            case .proposed:
                return next == LenientRevocationSummaryStatus.approved || next == LenientRevocationSummaryStatus.rejected
            case .approved:
                return next == LenientRevocationSummaryStatus.rejected || next == LenientRevocationSummaryStatus.withdrawn
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

        func moveTo(_ next: LenientRevocationSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient revocation summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func measuredValue() -> Double {
            return cost
        }

        func copyValue() -> LenientRevocationSummary {
            return LenientRevocationSummary(
                code: code,
                label: label,
                unit: unit,
                cost: cost,
                tags: tags,
                procedureCode: procedureCode,
                allergy: allergy,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a lenient revocation summary in status proposed.
    static func newLenientRevocationSummary(_ code: String, label: String) -> LenientRevocationSummary {
        return LenientRevocationSummary(
            code: code,
            label: label,
            unit: "",
            cost: 0.0,
            tags: [],
            procedureCode: "",
            allergy: "",
            facility: "",
            status: LenientRevocationSummaryStatus.proposed
        )
    }
}
