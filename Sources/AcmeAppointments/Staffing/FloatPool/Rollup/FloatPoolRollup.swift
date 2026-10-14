import AcmePlatform
import Foundation

extension Staffing {
    /// Where a float pool rollup is in its life cycle.
    enum FloatPoolRollupStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a float pool rollup and its current status.
    final class FloatPoolRollup {
        var code: String
        var label: String
        var windowDays: Int
        var notes: String
        var externalRef: String
        var batchSize: Int
        var timezone: String
        var quantity: Int
        var floorValue: Double
        var startsAt: Int
        var diagnosisCode: String
        var status: FloatPoolRollupStatus

        init(code: String, label: String, windowDays: Int, notes: String, externalRef: String, batchSize: Int, timezone: String, quantity: Int, floorValue: Double, startsAt: Int, diagnosisCode: String, status: FloatPoolRollupStatus) {
            self.code = code
            self.label = label
            self.windowDays = windowDays
            self.notes = notes
            self.externalRef = externalRef
            self.batchSize = batchSize
            self.timezone = timezone
            self.quantity = quantity
            self.floorValue = floorValue
            self.startsAt = startsAt
            self.diagnosisCode = diagnosisCode
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

        func canMoveTo(_ next: FloatPoolRollupStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == FloatPoolRollupStatus.closed
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

        func moveTo(_ next: FloatPoolRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("float pool rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("float pool rollup") \(code)"
        }

        func effectiveExposure() -> Double {
            return ((Double(startsAt) - floorValue) * 100).rounded() / 100
        }

        func copyValue() -> FloatPoolRollup {
            return FloatPoolRollup(
                code: code,
                label: label,
                windowDays: windowDays,
                notes: notes,
                externalRef: externalRef,
                batchSize: batchSize,
                timezone: timezone,
                quantity: quantity,
                floorValue: floorValue,
                startsAt: startsAt,
                diagnosisCode: diagnosisCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a float pool rollup in status draft.
    static func newFloatPoolRollup(_ code: String, label: String) -> FloatPoolRollup {
        return FloatPoolRollup(
            code: code,
            label: label,
            windowDays: 0,
            notes: "",
            externalRef: "",
            batchSize: 0,
            timezone: "",
            quantity: 0,
            floorValue: 0.0,
            startsAt: 0,
            diagnosisCode: "",
            status: FloatPoolRollupStatus.draft
        )
    }
}
