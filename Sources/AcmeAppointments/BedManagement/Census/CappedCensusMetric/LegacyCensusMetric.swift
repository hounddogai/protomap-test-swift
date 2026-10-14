import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a legacy census metric is in its life cycle.
    enum LegacyCensusMetricStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a legacy census metric and its current status.
    final class LegacyCensusMetric {
        var code: String
        var name: String
        var maximum: Double
        var notes: String
        var version: Int
        var tags: [String]
        var payer: String
        var phone: String
        var unit: String
        var status: LegacyCensusMetricStatus

        init(code: String, name: String, maximum: Double, notes: String, version: Int, tags: [String], payer: String, phone: String, unit: String, status: LegacyCensusMetricStatus) {
            self.code = code
            self.name = name
            self.maximum = maximum
            self.notes = notes
            self.version = version
            self.tags = tags
            self.payer = payer
            self.phone = phone
            self.unit = unit
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LegacyCensusMetricStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == LegacyCensusMetricStatus.reopened
            case .reopened:
                return next == LegacyCensusMetricStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyCensusMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy census metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
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

        func effectiveValue() -> Double {
            return ((Double(version) + maximum) * 100).rounded() / 100
        }

        func copyValue() -> LegacyCensusMetric {
            return LegacyCensusMetric(
                code: code,
                name: name,
                maximum: maximum,
                notes: notes,
                version: version,
                tags: tags,
                payer: payer,
                phone: phone,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a legacy census metric in status open.
    static func newLegacyCensusMetric(_ code: String, name: String) -> LegacyCensusMetric {
        return LegacyCensusMetric(
            code: code,
            name: name,
            maximum: 0.0,
            notes: "",
            version: 0,
            tags: [],
            payer: "",
            phone: "",
            unit: "",
            status: LegacyCensusMetricStatus.`open`
        )
    }
}
