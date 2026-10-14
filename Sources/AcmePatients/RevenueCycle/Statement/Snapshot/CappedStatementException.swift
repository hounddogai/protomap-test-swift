import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a capped statement exception is in its life cycle.
    enum CappedStatementExceptionStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a capped statement exception and its current status.
    final class CappedStatementException {
        var code: String
        var label: String
        var tags: [String]
        var allergy: String
        var notes: String
        var graceDays: Int
        var maximum: Double
        var name: String
        var revision: Int
        var floorValue: Double
        var status: CappedStatementExceptionStatus

        init(code: String, label: String, tags: [String], allergy: String, notes: String, graceDays: Int, maximum: Double, name: String, revision: Int, floorValue: Double, status: CappedStatementExceptionStatus) {
            self.code = code
            self.label = label
            self.tags = tags
            self.allergy = allergy
            self.notes = notes
            self.graceDays = graceDays
            self.maximum = maximum
            self.name = name
            self.revision = revision
            self.floorValue = floorValue
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

        func canMoveTo(_ next: CappedStatementExceptionStatus) -> Bool {
            switch status {
            case .created:
                return next == CappedStatementExceptionStatus.validated || next == CappedStatementExceptionStatus.retired
            case .validated:
                return next == CappedStatementExceptionStatus.published || next == CappedStatementExceptionStatus.retired
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

        func moveTo(_ next: CappedStatementExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped statement exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\("capped statement exception") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveVolume() -> Double {
            return ((maximum + Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> CappedStatementException {
            return CappedStatementException(
                code: code,
                label: label,
                tags: tags,
                allergy: allergy,
                notes: notes,
                graceDays: graceDays,
                maximum: maximum,
                name: name,
                revision: revision,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a capped statement exception in status created.
    static func newCappedStatementException(_ code: String, label: String) -> CappedStatementException {
        return CappedStatementException(
            code: code,
            label: label,
            tags: [],
            allergy: "",
            notes: "",
            graceDays: 0,
            maximum: 0.0,
            name: "",
            revision: 0,
            floorValue: 0.0,
            status: CappedStatementExceptionStatus.created
        )
    }
}
