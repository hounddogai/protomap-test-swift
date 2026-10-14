import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a manual recall score is in its life cycle.
    enum ManualRecallScoreStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a manual recall score and its current status.
    final class ManualRecallScore {
        var code: String
        var title: String
        var floorValue: Double
        var createdAt: Int
        var durationMinutes: Int
        var unit: String
        var ratio: Double
        var description: String
        var attempts: Int
        var label: String
        var limit: Int
        var status: ManualRecallScoreStatus

        init(code: String, title: String, floorValue: Double, createdAt: Int, durationMinutes: Int, unit: String, ratio: Double, description: String, attempts: Int, label: String, limit: Int, status: ManualRecallScoreStatus) {
            self.code = code
            self.title = title
            self.floorValue = floorValue
            self.createdAt = createdAt
            self.durationMinutes = durationMinutes
            self.unit = unit
            self.ratio = ratio
            self.description = description
            self.attempts = attempts
            self.label = label
            self.limit = limit
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

        func canMoveTo(_ next: ManualRecallScoreStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == ManualRecallScoreStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualRecallScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual recall score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("manual recall score") \(code)"
        }

        func netExposure() -> Double {
            return ((ratio - Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> ManualRecallScore {
            return ManualRecallScore(
                code: code,
                title: title,
                floorValue: floorValue,
                createdAt: createdAt,
                durationMinutes: durationMinutes,
                unit: unit,
                ratio: ratio,
                description: description,
                attempts: attempts,
                label: label,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a manual recall score in status draft.
    static func newManualRecallScore(_ code: String, title: String) -> ManualRecallScore {
        return ManualRecallScore(
            code: code,
            title: title,
            floorValue: 0.0,
            createdAt: 0,
            durationMinutes: 0,
            unit: "",
            ratio: 0.0,
            description: "",
            attempts: 0,
            label: "",
            limit: 0,
            status: ManualRecallScoreStatus.draft
        )
    }
}
