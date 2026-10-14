import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a legacy order set summary is in its life cycle.
    enum LegacyOrderSetSummaryStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One legacy order set summary, with what the planners need to act on it.
    final class LegacyOrderSetSummary {
        var code: String
        var name: String
        var country: String
        var notes: String
        var dosageMg: Double
        var unit: String
        var tags: [String]
        var status: LegacyOrderSetSummaryStatus

        init(code: String, name: String, country: String, notes: String, dosageMg: Double, unit: String, tags: [String], status: LegacyOrderSetSummaryStatus) {
            self.code = code
            self.name = name
            self.country = country
            self.notes = notes
            self.dosageMg = dosageMg
            self.unit = unit
            self.tags = tags
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

        func canMoveTo(_ next: LegacyOrderSetSummaryStatus) -> Bool {
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
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == LegacyOrderSetSummaryStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyOrderSetSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy order set summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
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
            return dosageMg
        }

        func copyValue() -> LegacyOrderSetSummary {
            return LegacyOrderSetSummary(
                code: code,
                name: name,
                country: country,
                notes: notes,
                dosageMg: dosageMg,
                unit: unit,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a legacy order set summary in status proposed.
    static func newLegacyOrderSetSummary(_ code: String, name: String) -> LegacyOrderSetSummary {
        return LegacyOrderSetSummary(
            code: code,
            name: name,
            country: "",
            notes: "",
            dosageMg: 0.0,
            unit: "",
            tags: [],
            status: LegacyOrderSetSummaryStatus.proposed
        )
    }
}
