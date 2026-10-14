import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a legacy statement exception is in its life cycle.
    enum LegacyStatementExceptionStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A legacy statement exception as the statement team keeps it.
    final class LegacyStatementException {
        var code: String
        var title: String
        var margin: Double
        var unit: String
        var attributes: [String: String]
        var bed: String
        var country: String
        var ward: String
        var status: LegacyStatementExceptionStatus

        init(code: String, title: String, margin: Double, unit: String, attributes: [String: String], bed: String, country: String, ward: String, status: LegacyStatementExceptionStatus) {
            self.code = code
            self.title = title
            self.margin = margin
            self.unit = unit
            self.attributes = attributes
            self.bed = bed
            self.country = country
            self.ward = ward
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

        func canMoveTo(_ next: LegacyStatementExceptionStatus) -> Bool {
            switch status {
            case .`open`:
                return next == LegacyStatementExceptionStatus.inReview || next == LegacyStatementExceptionStatus.archived
            case .inReview:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: LegacyStatementExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy statement exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("legacy statement exception") \(code)"
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

        func measuredValue() -> Double {
            return margin
        }

        func copyValue() -> LegacyStatementException {
            return LegacyStatementException(
                code: code,
                title: title,
                margin: margin,
                unit: unit,
                attributes: attributes,
                bed: bed,
                country: country,
                ward: ward,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a legacy statement exception in status open.
    static func newLegacyStatementException(_ code: String, title: String) -> LegacyStatementException {
        return LegacyStatementException(
            code: code,
            title: title,
            margin: 0.0,
            unit: "",
            attributes: [:],
            bed: "",
            country: "",
            ward: "",
            status: LegacyStatementExceptionStatus.`open`
        )
    }
}
